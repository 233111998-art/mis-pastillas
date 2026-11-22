import 'package:flutter_test/flutter_test.dart';
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

  test('guardar y leer una pastilla', () {
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
    expect(copia.esPermanente, isTrue);
    expect(copia.fechaFin, isNull);
    expect(copia.activaEn(DateTime(2030, 1, 1)), isTrue);
  });
}
