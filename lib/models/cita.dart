import '../utils/fechas.dart';

/// Consulta con el doctor o estudio de laboratorio.
enum TipoCita { consulta, laboratorio }

extension TipoCitaTexto on TipoCita {
  String get nombre => this == TipoCita.consulta ? 'Consulta' : 'Laboratorio';
  String get plural => this == TipoCita.consulta ? 'Consultas' : 'Laboratorios';
}

class Cita {
  Cita({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.fecha,
    this.lugar = '',
    this.notas = '',
    this.ayunas = false,
    this.avisoDiaAntes = true,
    this.avisoHorasAntes = 2,
  });

  final String id;
  final TipoCita tipo;

  /// "Cardiólogo", "Dr. Pérez", "Química sanguínea"...
  final String titulo;

  /// Día y hora de la cita (hora local).
  final DateTime fecha;

  final String lugar;
  final String notas;

  /// Para laboratorio: hay que ir en ayunas.
  final bool ayunas;

  /// Avisar el día anterior en la noche.
  final bool avisoDiaAntes;

  /// Avisar X horas antes (0 = no avisar).
  final int avisoHorasAntes;

  bool get esLaboratorio => tipo == TipoCita.laboratorio;

  int get minutos => fecha.hour * 60 + fecha.minute;

  bool yaPaso(DateTime ahora) => fecha.isBefore(ahora);

  /// "Mañana · 10:00 a. m."
  String cuando(DateTime ahora) =>
      '${fechaRelativa(fecha, ahora)} · ${formatoHoraDe(fecha)}';

  Cita copyWith({
    TipoCita? tipo,
    String? titulo,
    DateTime? fecha,
    String? lugar,
    String? notas,
    bool? ayunas,
    bool? avisoDiaAntes,
    int? avisoHorasAntes,
  }) {
    return Cita(
      id: id,
      tipo: tipo ?? this.tipo,
      titulo: titulo ?? this.titulo,
      fecha: fecha ?? this.fecha,
      lugar: lugar ?? this.lugar,
      notas: notas ?? this.notas,
      ayunas: ayunas ?? this.ayunas,
      avisoDiaAntes: avisoDiaAntes ?? this.avisoDiaAntes,
      avisoHorasAntes: avisoHorasAntes ?? this.avisoHorasAntes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tipo': tipo.name,
        'titulo': titulo,
        'fecha': fecha.toIso8601String(),
        'lugar': lugar,
        'notas': notas,
        'ayunas': ayunas,
        'avisoDiaAntes': avisoDiaAntes,
        'avisoHorasAntes': avisoHorasAntes,
      };

  factory Cita.fromJson(Map<String, dynamic> json) {
    return Cita(
      id: json['id'] as String,
      tipo: json['tipo'] == TipoCita.laboratorio.name
          ? TipoCita.laboratorio
          : TipoCita.consulta,
      titulo: (json['titulo'] as String?) ?? '',
      fecha: DateTime.parse(json['fecha'] as String),
      lugar: (json['lugar'] as String?) ?? '',
      notas: (json['notas'] as String?) ?? '',
      ayunas: (json['ayunas'] as bool?) ?? false,
      avisoDiaAntes: (json['avisoDiaAntes'] as bool?) ?? true,
      avisoHorasAntes: (json['avisoHorasAntes'] as num?)?.toInt() ?? 0,
    );
  }
}
