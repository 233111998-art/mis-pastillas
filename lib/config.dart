/// Ajustes rápidos de la app.

/// Nombre que aparece arriba en la app.
const String kNombreApp = 'Mis Pastillas';

/// Máximo de días para un tratamiento temporal (Android permite
/// un número limitado de avisos programados por app).
const int kMaxDiasTemporal = 90;

/// Cuántos minutos ANTES de la hora se puede marcar "Ya me la tomé".
/// 0 = el botón se activa exactamente a la hora de la toma.
/// (Por ejemplo, con 15 se podría marcar desde las 7:45 una toma de las 8:00).
const int kMinutosAntesPermitidos = 0;

/// Hora del aviso "mañana tienes cita" (minutos desde la medianoche).
const int kHoraAvisoDiaAntes = 20 * 60; // 8:00 p. m.
