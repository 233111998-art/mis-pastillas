import 'package:flutter_test/flutter_test.dart';
import 'package:sukey_pastillas/models/cita.dart';
import 'package:sukey_pastillas/models/medicina.dart';
import 'package:sukey_pastillas/utils/fechas.dart';

void main() {
  test('formato de hora en 12 horas', () {
    expect(formatoHora(0), '12:00 a. m.');
    expect(formatoHora(8 * 60), '8:00 a. m.');
    expect(formatoHora(12 * 60 + 30), '12:30 p. m.');
    expect(formatoHora(20 * 60 + 5), '8:05 p. m.');
  });

  test('un aviso diario tocado después de medianoche es del día anterior', () {
    final ahora = DateTime(2026, 11, 22, 0, 30);
    expect(diaDeLaDosis(22 * 60, ahora), DateTime(2026, 11, 21));
    expect(diaDeLaDosis(0, ahora), DateTime(2026, 11, 22));
  });

  test('el botón "Ya me la tomé" se activa hasta la hora', () {
    final dia = DateTime(2026, 11, 21);
    expect(tomaDisponible(dia, 20 * 60, DateTime(2026, 11, 21, 19, 59)), isFalse);
    expect(tomaDisponible(dia, 20 * 60, DateTime(2026, 11, 21, 20, 0)), isTrue);
    expect(tomaDisponible(dia, 20 * 60, DateTime(2026, 11, 22, 9, 0)), isTrue);
  });

  test('tratamiento temporal de 7 días', () {
    final m = Medicina(
      id: '1',
      nombre: 'Amoxicilina',
      tipo: TipoTratamiento.temporal,
      horarios: const [20 * 60, 8 * 60, 8 * 60],
      fechaInicio: DateTime(2026, 11, 21, 15),
      dias: 7,
    );
    expect(m.horarios, [8 * 60, 20 * 60]); // ordenadas y sin repetir
    expect(m.fechaFin, DateTime(2026, 11, 27));
    expect(m.activaEn(DateTime(2026, 11, 20)), isFalse);
    expect(m.activaEn(DateTime(2026, 11, 27, 23)), isTrue);
    expect(m.activaEn(DateTime(2026, 11, 28)), isFalse);
    expect(m.diasRestantes(DateTime(2026, 11, 27)), 1);
    expect(m.terminadaEn(DateTime(2026, 11, 28)), isTrue);
  });

  test('dosis distinta según el día de la semana', () {
    // 2026-11-23 es lunes.
    final m = Medicina(
      id: 'w',
      nombre: 'Warfarina',
      tipo: TipoTratamiento.permanente,
      horarios: const [20 * 60],
      fechaInicio: DateTime(2026, 11, 1),
      dosisPorDia: const {1: '1 tableta', 2: '1 tableta', 3: '½ tableta', 4: '½ tableta', 5: '½ tableta'},
    );
    expect(m.cambiaPorDia, isTrue);
    expect(m.dosisEn(DateTime(2026, 11, 23)), '1 tableta'); // lunes
    expect(m.dosisEn(DateTime(2026, 11, 25)), '½ tableta'); // miércoles
    expect(m.activaEn(DateTime(2026, 11, 28)), isFalse); // sábado: no toca
    expect(m.tituloEn(DateTime(2026, 11, 24)), 'Warfarina 1 tableta');
    expect(m.resumenDosisPorDia(), [
      'Lun y Mar: 1 tableta',
      'Mié a Vie: ½ tableta',
      'Sáb y Dom: no toca',
    ]);

    final copia = Medicina.fromJson(m.toJson());
    expect(copia.dosisPorDia, m.dosisPorDia);
  });

  test('guardar y leer una pastilla de dosis fija', () {
    final m = Medicina(
      id: 'abc',
      nombre: 'Losartán',
      dosis: '50 mg',
      tipo: TipoTratamiento.permanente,
      horarios: const [8 * 60],
      fechaInicio: DateTime(2026, 11, 21),
    );
    final copia = Medicina.fromJson(m.toJson());
    expect(copia.titulo, 'Losartán 50 mg');
    expect(copia.cambiaPorDia, isFalse);
    expect(copia.fechaFin, isNull);
    expect(copia.activaEn(DateTime(2030, 1, 1)), isTrue);
  });

  test('texto de días', () {
    expect(textoDias([1, 2, 3, 4, 5, 6, 7]), 'Todos los días');
    expect(textoDias([1, 3, 5]), 'Lun, Mié y Vie');
    expect(textoDias([6, 7]), 'Sáb y Dom');
  });

  test('guardar y leer una cita', () {
    final c = Cita(
      id: 'c1',
      tipo: TipoCita.laboratorio,
      titulo: 'Química sanguínea',
      fecha: DateTime(2026, 11, 25, 8, 0),
      ayunas: true,
    );
    final copia = Cita.fromJson(c.toJson());
    expect(copia.esLaboratorio, isTrue);
    expect(copia.ayunas, isTrue);
    expect(copia.fecha, DateTime(2026, 11, 25, 8, 0));
    expect(copia.cuando(DateTime(2026, 11, 24, 12)), 'Mañana · 8:00 a. m.');
  });
}
