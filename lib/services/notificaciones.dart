import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../config.dart';
import '../models/medicina.dart';
import '../utils/fechas.dart';

/// Lo que pasó cuando tocaron un aviso.
class RespuestaAviso {
  const RespuestaAviso({
    required this.medId,
    required this.minutos,
    required this.dia,
    required this.desdeBoton,
  });

  final String medId;
  final int minutos;
  final DateTime dia;

  /// true si tocaron el botón "Ya me la tomé" del aviso.
  final bool desdeBoton;

  bool get esPrueba => medId == Notificaciones.idPrueba;
}

/// Programa los avisos de cada pastilla y recibe cuando los tocan.
class Notificaciones {
  Notificaciones._();
  static final Notificaciones instance = Notificaciones._();

  static const String canalId = 'recordatorio_pastillas';
  static const String canalNombre = 'Recordatorios de pastillas';
  static const String accionTomada = 'ya_me_la_tome';
  static const String categoriaIOS = 'dosis';
  static const String idPrueba = 'prueba';

  /// Android limita cuántas alarmas puede tener una app; dejamos margen.
  static const int _maxAvisos = 450;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _listo = false;

  /// La app conecta aquí qué hacer cuando tocan un aviso.
  void Function(RespuestaAviso respuesta)? alTocar;

  /// Si la app se abrió desde un aviso estando cerrada.
  RespuestaAviso? respuestaInicial;

  bool get _esAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  bool get _esIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  IOSFlutterLocalNotificationsPlugin? get _ios =>
      _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

  // ---------------------------------------------------------------------------
  // Inicio y permisos
  // ---------------------------------------------------------------------------

  Future<void> iniciar() async {
    if (!_esAndroid && !_esIOS) return;

    await _configurarZonaHoraria();

    const android = AndroidInitializationSettings('ic_notificacion');
    final ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          categoriaIOS,
          actions: [
            DarwinNotificationAction.plain(
              accionTomada,
              'Ya me la tomé',
              options: {DarwinNotificationActionOption.foreground},
            ),
          ],
        ),
      ],
    );

    await _plugin.initialize(
      settings: InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _alRecibirRespuesta,
    );

    final lanzamiento = await _plugin.getNotificationAppLaunchDetails();
    final respuesta = lanzamiento?.notificationResponse;
    if ((lanzamiento?.didNotificationLaunchApp ?? false) && respuesta != null) {
      respuestaInicial = _interpretar(respuesta);
    }

    await _android?.createNotificationChannel(
      const AndroidNotificationChannel(
        canalId,
        canalNombre,
        description: 'Avisos para tomar tus pastillas a tiempo',
        importance: Importance.max,
      ),
    );

    _listo = true;
  }

  Future<void> _configurarZonaHoraria() async {
    tzdata.initializeTimeZones();
    try {
      final zona = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zona.identifier));
    } catch (e) {
      debugPrint('No se pudo leer la zona horaria, uso Ciudad de México: $e');
      try {
        tz.setLocalLocation(tz.getLocation('America/Mexico_City'));
      } catch (_) {}
    }
  }

  /// Pide permiso para mostrar avisos (Android 13+ y iPhone).
  Future<bool> pedirPermisos() async {
    if (_esAndroid) {
      final ok = await _android?.requestNotificationsPermission();
      return ok ?? false;
    }
    if (_esIOS) {
      final ok = await _ios?.requestPermissions(alert: true, badge: true, sound: true);
      return ok ?? false;
    }
    return false;
  }

  Future<bool> avisosActivados() async {
    if (_esAndroid) return await _android?.areNotificationsEnabled() ?? false;
    return true;
  }

  Future<bool> alarmasExactasPermitidas() async {
    if (!_esAndroid) return true;
    return await _android?.canScheduleExactNotifications() ?? false;
  }

  Future<void> pedirAlarmasExactas() async {
    if (_esAndroid) await _android?.requestExactAlarmsPermission();
  }

  // ---------------------------------------------------------------------------
  // Respuestas
  // ---------------------------------------------------------------------------

  void _alRecibirRespuesta(NotificationResponse respuesta) {
    final r = _interpretar(respuesta);
    if (r != null) alTocar?.call(r);
  }

  RespuestaAviso? _interpretar(NotificationResponse respuesta) {
    final payload = respuesta.payload;
    if (payload == null || payload.isEmpty) return null;
    try {
      final datos = jsonDecode(payload) as Map<String, dynamic>;
      final minutos = (datos['min'] as num).toInt();
      final fecha = datos['fecha'] as String?;
      return RespuestaAviso(
        medId: datos['med'] as String,
        minutos: minutos,
        dia: fecha != null ? fechaDesdeClave(fecha) : diaDeLaDosis(minutos, DateTime.now()),
        desdeBoton: respuesta.actionId == accionTomada,
      );
    } catch (e) {
      debugPrint('Aviso con datos desconocidos: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Programación
  // ---------------------------------------------------------------------------

  NotificationDetails _detalles(String cuerpoLargo) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        canalId,
        canalNombre,
        channelDescription: 'Avisos para tomar tus pastillas a tiempo',
        icon: 'ic_notificacion',
        color: const Color(0xFF6F4E37),
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
        ticker: 'Hora de tu pastilla',
        styleInformation: BigTextStyleInformation(cuerpoLargo),
        actions: const [
          AndroidNotificationAction(
            accionTomada,
            'Ya me la tomé ✓',
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
      ),
      iOS: const DarwinNotificationDetails(
        categoryIdentifier: categoriaIOS,
        presentAlert: true,
        presentSound: true,
      ),
    );
  }

  Future<AndroidScheduleMode> _modo() async {
    if (!_esAndroid) return AndroidScheduleMode.exactAllowWhileIdle;
    final exactas = await alarmasExactasPermitidas();
    return exactas
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  /// Borra los avisos pendientes y los vuelve a programar todos.
  Future<void> reprogramar(List<Medicina> medicinas) async {
    if (!_listo) return;

    await _plugin.cancelAllPendingNotifications();

    final modo = await _modo();
    final ahora = tz.TZDateTime.now(tz.local);
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    var id = 1;

    for (final m in medicinas) {
      if (m.terminadaEn(hoy)) continue;

      for (final minutos in m.horarios) {
        if (id > _maxAvisos) return;

        if (m.esPermanente) {
          // Un solo aviso que se repite todos los días a la misma hora.
          var cuando = tz.TZDateTime(
            tz.local, ahora.year, ahora.month, ahora.day, minutos ~/ 60, minutos % 60);
          if (!cuando.isAfter(ahora)) cuando = cuando.add(const Duration(days: 1));
          await _programar(id++, m, minutos, cuando, modo, repetirDiario: true);
        } else {
          // Un aviso por cada día que falta del tratamiento.
          final fin = m.fechaFin!;
          var dia = m.fechaInicio.isAfter(hoy) ? m.fechaInicio : hoy;
          while (!dia.isAfter(fin) && id <= _maxAvisos) {
            final cuando = tz.TZDateTime(
                tz.local, dia.year, dia.month, dia.day, minutos ~/ 60, minutos % 60);
            if (cuando.isAfter(ahora)) {
              await _programar(id++, m, minutos, cuando, modo, dia: dia);
            }
            dia = sumarDias(dia, 1);
          }
        }
      }
    }
  }

  Future<void> _programar(
    int id,
    Medicina m,
    int minutos,
    tz.TZDateTime cuando,
    AndroidScheduleMode modo, {
    bool repetirDiario = false,
    DateTime? dia,
  }) async {
    final hora = formatoHora(minutos);
    final cuerpo = '${m.titulo} · $hora';
    final notas = m.notas.trim().isEmpty ? '' : '\n${m.notas.trim()}';
    final cuerpoLargo = '$cuerpo$notas\nToca aquí cuando te la tomes.';

    await _plugin.zonedSchedule(
      id: id,
      title: '$kNombreUsuaria, es hora de tu pastilla 💊',
      body: cuerpo,
      scheduledDate: cuando,
      notificationDetails: _detalles(cuerpoLargo),
      androidScheduleMode: modo,
      matchDateTimeComponents: repetirDiario ? DateTimeComponents.time : null,
      payload: jsonEncode({
        'med': m.id,
        'min': minutos,
        if (dia != null) 'fecha': claveFecha(dia),
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Pruebas
  // ---------------------------------------------------------------------------

  static const int _idPruebaAhora = 900001;
  static const int _idPruebaMinuto = 900002;

  String get _payloadPrueba => jsonEncode({'med': idPrueba, 'min': 0});

  Future<void> mostrarPrueba() async {
    if (!_listo) return;
    await _plugin.show(
      id: _idPruebaAhora,
      title: 'Así se verán tus avisos 💊',
      body: 'Toca aquí o en "Ya me la tomé" para probar.',
      notificationDetails: _detalles('Toca aquí o en "Ya me la tomé" para probar.'),
      payload: _payloadPrueba,
    );
  }

  Future<void> programarPruebaEnUnMinuto() async {
    if (!_listo) return;
    await _plugin.zonedSchedule(
      id: _idPruebaMinuto,
      title: 'Aviso de prueba 💊',
      body: 'Si ves esto, los avisos programados funcionan.',
      scheduledDate: tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1)),
      notificationDetails: _detalles('Si ves esto, los avisos programados funcionan.'),
      androidScheduleMode: await _modo(),
      payload: _payloadPrueba,
    );
  }
}
