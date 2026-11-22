import '../config.dart';
import '../utils/fechas.dart';

/// Para siempre (ej. Losartán) o solo por unos días (ej. un antibiótico).
enum TipoTratamiento { permanente, temporal }

class Medicina {
  Medicina({
    required this.id,
    required this.nombre,
    this.dosis = '',
    Map<int, String>? dosisPorDia,
    this.notas = '',
    required this.tipo,
    required List<int> horarios,
    required DateTime fechaInicio,
    this.dias = 7,
    this.color = 0,
  })  : horarios = List.unmodifiable(horarios.toSet().toList()..sort()),
        dosisPorDia = Map.unmodifiable(dosisPorDia ?? const <int, String>{}),
        fechaInicio = soloFecha(fechaInicio);

  final String id;
  final String nombre;

  /// Dosis cuando es la misma todos los días: "50 mg", "1 tableta"...
  final String dosis;

  /// Dosis que cambia según el día de la semana (1 = lunes … 7 = domingo).
  /// Si está vacío, la dosis es la misma todos los días ([dosis]).
  /// Si tiene datos, los días que NO aparecen aquí no le toca la pastilla.
  final Map<int, String> dosisPorDia;

  final String notas;
  final TipoTratamiento tipo;

  /// Horas de toma, en minutos desde la medianoche (8:00 a. m. = 480).
  final List<int> horarios;

  /// Día en que empieza (para las permanentes, el día en que se agregó).
  final DateTime fechaInicio;

  /// Cuántos días dura (solo para temporales).
  final int dias;

  /// Índice del color en la paleta de pastillas.
  final int color;

  bool get esPermanente => tipo == TipoTratamiento.permanente;

  /// La dosis cambia según el día de la semana.
  bool get cambiaPorDia => dosisPorDia.isNotEmpty;

  /// Nombre + dosis (si la dosis es fija). Para listas generales.
  String get titulo {
    final d = cambiaPorDia ? '' : dosis.trim();
    return d.isEmpty ? nombre : '$nombre $d';
  }

  /// Dosis de ese día, o null si ese día no le toca.
  String? dosisEn(DateTime dia) {
    if (!cambiaPorDia) return dosis.trim();
    final d = dosisPorDia[dia.weekday];
    return d?.trim();
  }

  /// Nombre + la dosis de ese día.
  String tituloEn(DateTime dia) {
    final d = dosisEn(dia) ?? '';
    return d.isEmpty ? nombre : '$nombre $d';
  }

  /// Último día de toma (solo temporales).
  DateTime? get fechaFin =>
      esPermanente ? null : sumarDias(fechaInicio, dias - 1);

  /// ¿Le toca tomarla ese día?
  bool activaEn(DateTime dia) {
    final d = soloFecha(dia);
    if (d.isBefore(fechaInicio)) return false;
    final fin = fechaFin;
    if (fin != null && d.isAfter(fin)) return false;
    if (cambiaPorDia && !dosisPorDia.containsKey(d.weekday)) return false;
    return true;
  }

  /// El tratamiento temporal ya terminó.
  bool terminadaEn(DateTime hoy) {
    final fin = fechaFin;
    return fin != null && soloFecha(hoy).isAfter(fin);
  }

  /// Todavía no empieza (temporal con fecha futura).
  bool porEmpezarEn(DateTime hoy) => soloFecha(hoy).isBefore(fechaInicio);

  /// Días que faltan contando hoy (solo temporales).
  int? diasRestantes(DateTime hoy) {
    final fin = fechaFin;
    if (fin == null) return null;
    if (porEmpezarEn(hoy)) return dias;
    final r = diasEntre(hoy, fin) + 1;
    return r < 0 ? 0 : r;
  }

  /// Resumen de dosis por día: ["Lun y Mar: 1 tableta", "Mié a Dom: ½ tableta"].
  List<String> resumenDosisPorDia() {
    if (!cambiaPorDia) return const [];
    // Agrupa los días que tienen la misma dosis, respetando el orden de la semana.
    final grupos = <String, List<int>>{};
    for (var dia = 1; dia <= 7; dia++) {
      final d = dosisPorDia[dia];
      if (d == null) continue;
      grupos.putIfAbsent(d.trim(), () => []).add(dia);
    }
    final lineas = [
      for (final e in grupos.entries)
        e.key.isEmpty ? textoDias(e.value) : '${textoDias(e.value)}: ${e.key}',
    ];
    final sinToma = [for (var dia = 1; dia <= 7; dia++) if (!dosisPorDia.containsKey(dia)) dia];
    if (sinToma.isNotEmpty) lineas.add('${textoDias(sinToma)}: no toca');
    return lineas;
  }

  Medicina copyWith({
    String? nombre,
    String? dosis,
    Map<int, String>? dosisPorDia,
    String? notas,
    TipoTratamiento? tipo,
    List<int>? horarios,
    DateTime? fechaInicio,
    int? dias,
    int? color,
  }) {
    return Medicina(
      id: id,
      nombre: nombre ?? this.nombre,
      dosis: dosis ?? this.dosis,
      dosisPorDia: dosisPorDia ?? this.dosisPorDia,
      notas: notas ?? this.notas,
      tipo: tipo ?? this.tipo,
      horarios: horarios ?? this.horarios,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      dias: dias ?? this.dias,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'dosis': dosis,
        'dosisPorDia': dosisPorDia.map((k, v) => MapEntry('$k', v)),
        'notas': notas,
        'tipo': tipo.name,
        'horarios': horarios,
        'inicio': claveFecha(fechaInicio),
        'dias': dias,
        'color': color,
      };

  factory Medicina.fromJson(Map<String, dynamic> json) {
    final porDia = <int, String>{};
    final crudo = json['dosisPorDia'];
    if (crudo is Map) {
      crudo.forEach((k, v) {
        final dia = int.tryParse('$k');
        if (dia != null && dia >= 1 && dia <= 7) porDia[dia] = '${v ?? ''}';
      });
    }
    return Medicina(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      dosis: (json['dosis'] as String?) ?? '',
      dosisPorDia: porDia,
      notas: (json['notas'] as String?) ?? '',
      tipo: json['tipo'] == TipoTratamiento.temporal.name
          ? TipoTratamiento.temporal
          : TipoTratamiento.permanente,
      horarios: (json['horarios'] as List).map((e) => (e as num).toInt()).toList(),
      fechaInicio: fechaDesdeClave(json['inicio'] as String),
      dias: (json['dias'] as num?)?.toInt() ?? 7,
      color: (json['color'] as num?)?.toInt() ?? 0,
    );
  }
}

enum EstadoDosis {
  /// Ya quedó registrada.
  tomada,

  /// Todavía no es la hora (el botón está bloqueado).
  pendiente,

  /// Ya es la hora o ya pasó y no se ha registrado (hoy).
  atrasada,

  /// Un día anterior que no se registró.
  sinRegistro,
}

/// Una toma concreta: una pastilla, un día y una hora.
class Dosis {
  const Dosis({
    required this.medicina,
    required this.dia,
    required this.minutos,
    this.tomadaA,
  });

  final Medicina medicina;
  final DateTime dia;
  final int minutos;
  final DateTime? tomadaA;

  DateTime get momento => momentoDeToma(dia, minutos);

  /// Nombre + dosis de ese día.
  String get titulo => medicina.tituloEn(dia);

  /// Solo la dosis de ese día ("1 tableta"), puede ser vacía.
  String get dosisTexto => medicina.dosisEn(dia) ?? '';

  /// ¿Ya se puede marcar "Ya me la tomé"?
  bool disponible(DateTime ahora) => tomaDisponible(dia, minutos, ahora);

  EstadoDosis estado(DateTime ahora) {
    if (tomadaA != null) return EstadoDosis.tomada;
    if (soloFecha(dia).isBefore(soloFecha(ahora))) return EstadoDosis.sinRegistro;
    return disponible(ahora) ? EstadoDosis.atrasada : EstadoDosis.pendiente;
  }
}

DateTime momentoDeToma(DateTime dia, int minutos) =>
    DateTime(dia.year, dia.month, dia.day, minutos ~/ 60, minutos % 60);

/// El botón "Ya me la tomé" se activa a la hora de la toma
/// (o [kMinutosAntesPermitidos] minutos antes).
bool tomaDisponible(DateTime dia, int minutos, DateTime ahora) {
  final desde = momentoDeToma(dia, minutos)
      .subtract(const Duration(minutes: kMinutosAntesPermitidos));
  return !ahora.isBefore(desde);
}

String claveToma(String medId, DateTime dia, int minutos) =>
    '$medId|${claveFecha(dia)}|$minutos';
