import '../utils/fechas.dart';

/// Para siempre (ej. Losartán) o solo por unos días (ej. un antibiótico).
enum TipoTratamiento { permanente, temporal }

class Medicina {
  Medicina({
    required this.id,
    required this.nombre,
    this.dosis = '',
    this.notas = '',
    required this.tipo,
    required List<int> horarios,
    required DateTime fechaInicio,
    this.dias = 7,
    this.color = 0,
  })  : horarios = List.unmodifiable(horarios.toSet().toList()..sort()),
        fechaInicio = soloFecha(fechaInicio);

  final String id;
  final String nombre;

  /// Texto libre: "50 mg", "1 tableta", "media pastilla"...
  final String dosis;
  final String notas;
  final TipoTratamiento tipo;

  /// Horas de toma, en minutos desde la medianoche (8:00 a. m. = 480).
  final List<int> horarios;

  /// Día en que empieza (para las permanentes, el día en que se agregó).
  final DateTime fechaInicio;

  /// Cuántos días dura (solo para temporales).
  final int dias;

  /// Índice del color en [Cafe.pastillas].
  final int color;

  bool get esPermanente => tipo == TipoTratamiento.permanente;

  String get titulo => dosis.trim().isEmpty ? nombre : '$nombre ${dosis.trim()}';

  /// Último día de toma (solo temporales).
  DateTime? get fechaFin =>
      esPermanente ? null : sumarDias(fechaInicio, dias - 1);

  /// ¿Le toca tomarla ese día?
  bool activaEn(DateTime dia) {
    final d = soloFecha(dia);
    if (d.isBefore(fechaInicio)) return false;
    final fin = fechaFin;
    if (fin != null && d.isAfter(fin)) return false;
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

  Medicina copyWith({
    String? nombre,
    String? dosis,
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
        'notas': notas,
        'tipo': tipo.name,
        'horarios': horarios,
        'inicio': claveFecha(fechaInicio),
        'dias': dias,
        'color': color,
      };

  factory Medicina.fromJson(Map<String, dynamic> json) {
    return Medicina(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      dosis: (json['dosis'] as String?) ?? '',
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

  /// Todavía no es la hora.
  pendiente,

  /// Ya pasó la hora y no se ha registrado (hoy).
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

  DateTime get momento =>
      DateTime(dia.year, dia.month, dia.day, minutos ~/ 60, minutos % 60);

  EstadoDosis estado(DateTime ahora) {
    if (tomadaA != null) return EstadoDosis.tomada;
    if (soloFecha(dia).isBefore(soloFecha(ahora))) return EstadoDosis.sinRegistro;
    return ahora.isBefore(momento) ? EstadoDosis.pendiente : EstadoDosis.atrasada;
  }
}

String claveToma(String medId, DateTime dia, int minutos) =>
    '$medId|${claveFecha(dia)}|$minutos';
