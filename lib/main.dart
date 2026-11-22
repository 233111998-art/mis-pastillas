import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'data/app_state.dart';
import 'services/notificaciones.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppState.instance.cargar();

  try {
    await Notificaciones.instance.iniciar();
  } catch (e) {
    debugPrint('No se pudieron iniciar los avisos: $e');
  }

  runApp(const SukeyApp());

  // Vuelve a programar todos los avisos cada vez que se abre la app
  // (así los tratamientos por días siempre quedan al corriente).
  unawaited(AppState.instance.reprogramarAvisos());
}
