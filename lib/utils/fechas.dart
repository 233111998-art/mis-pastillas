/// Ayudantes para fechas y horas en español (sin paquetes extra).

const List<String> _dias = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];

const List<String> _meses = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

/// Quita la hora y deja solo el día.
DateTime soloFecha(DateTime d) => DateTime(d.year, d.month, d.day);

/// Suma (o resta) días de calendario sin problemas de horario de verano.
DateTime sumarDias(DateTime d, int dias) => DateTime(d.year, d.month, d.day + dias);

/// Días de calendario entre dos fechas (b - a).
int diasEntre(DateTime a, DateTime b) {
  final ua = DateTime.utc(a.year, a.month, a.day);
  final ub = DateTime.utc(b.year, b.month, b.day);
  return ub.difference(ua).inDays;
}

bool mismoDia(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// "2026-11-21"
String claveFecha(DateTime d) {
  final m = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return '${d.year}-$m-$dd';
}

DateTime fechaDesdeClave(String clave) {
  final partes = clave.split('-');
  return DateTime(
    int.parse(partes[0]),
    int.parse(partes[1]),
    int.parse(partes[2]),
  );
}

/// Minutos desde la medianoche -> "8:00 a. m."
String formatoHora(int minutos) {
  final h = minutos ~/ 60;
  final m = (minutos % 60).toString().padLeft(2, '0');
  final sufijo = h < 12 ? 'a. m.' : 'p. m.';
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12:$m $sufijo';
}

String formatoHoraDe(DateTime t) => formatoHora(t.hour * 60 + t.minute);

String _capital(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// "Sábado 21 de noviembre"
String fechaLarga(DateTime d) =>
    '${_capital(_dias[d.weekday - 1])} ${d.day} de ${_meses[d.month - 1]}';

/// "sábado 21 de nov."
String fechaCorta(DateTime d) =>
    '${_dias[d.weekday - 1]} ${d.day} de ${_meses[d.month - 1].substring(0, 3)}.';

/// "Hoy", "Ayer", "Mañana" o la fecha larga.
String fechaRelativa(DateTime d, DateTime ahora) {
  final dif = diasEntre(ahora, d);
  if (dif == 0) return 'Hoy';
  if (dif == -1) return 'Ayer';
  if (dif == 1) return 'Mañana';
  return fechaLarga(d);
}

String saludo(DateTime ahora) {
  if (ahora.hour < 12) return 'Buenos días';
  if (ahora.hour < 19) return 'Buenas tardes';
  return 'Buenas noches';
}

/// ¿De qué día es la dosis de un aviso que se repite diario?
/// El aviso suena a la hora de la dosis, así que si ahora es más temprano
/// que esa hora, el aviso es de ayer (por ejemplo, el de las 10 p. m.
/// tocado a las 12:30 a. m.).
DateTime diaDeLaDosis(int minutosDosis, DateTime ahora) {
  final minutosAhora = ahora.hour * 60 + ahora.minute;
  final hoy = soloFecha(ahora);
  return minutosAhora >= minutosDosis ? hoy : sumarDias(hoy, -1);
}
