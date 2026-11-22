import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'config.dart';
import 'data/app_state.dart';
import 'screens/bienvenida_screen.dart';
import 'screens/inicio_screen.dart';
import 'services/notificaciones.dart';
import 'theme.dart';
import 'widgets/confirmar_toma_sheet.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> mensajeroKey =
    GlobalKey<ScaffoldMessengerState>();

Route<void> crearRutaInicio() => PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (_, _, _) => const InicioScreen(),
      transitionsBuilder: (_, animacion, _, hijo) => FadeTransition(
        opacity: CurvedAnimation(parent: animacion, curve: Curves.easeOut),
        child: hijo,
      ),
    );

void mostrarMensaje(String texto, {SnackBarAction? accion}) {
  final mensajero = mensajeroKey.currentState;
  if (mensajero == null) return;
  mensajero
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(texto), action: accion));
}

class SukeyApp extends StatefulWidget {
  const SukeyApp({super.key});

  @override
  State<SukeyApp> createState() => _SukeyAppState();
}

class _SukeyAppState extends State<SukeyApp> with WidgetsBindingObserver {
  RespuestaAviso? _respuestaInicial;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final avisos = Notificaciones.instance;
    avisos.alTocar = _atenderAviso;

    // Si la app se abrió tocando un aviso, saltamos la bienvenida
    // y mostramos directo la pregunta "¿Ya te la tomaste?".
    _respuestaInicial = avisos.respuestaInicial;
    avisos.respuestaInicial = null;
    final inicial = _respuestaInicial;
    if (inicial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _mostrarAviso(inicial));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Actualiza "pendiente" / "ya pasó la hora" al volver a la app.
      AppState.instance.refrescar();
    }
  }

  /// Llega un aviso tocado mientras la app está abierta o en segundo plano.
  void _atenderAviso(RespuestaAviso respuesta) {
    final nav = navigatorKey.currentState;
    if (nav == null) return;

    // Cierra lo que esté abierto encima y asegura estar en la pantalla principal.
    nav.popUntil((ruta) => ruta.isFirst);
    if (!InicioScreen.estaAbierta) {
      nav.pushAndRemoveUntil(crearRutaInicio(), (_) => false);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _mostrarAviso(respuesta));
  }

  Future<void> _mostrarAviso(RespuestaAviso respuesta) async {
    AppState.instance.pestana.value = 0;

    if (respuesta.esPrueba) {
      mostrarMensaje(respuesta.desdeBoton
          ? '¡Funciona! Así se registra con el botón del aviso.'
          : '¡Funciona! Así se abre la app desde el aviso.');
      return;
    }

    final estado = AppState.instance;
    final medicina = estado.buscar(respuesta.medId);
    if (medicina == null) {
      mostrarMensaje('Esa pastilla ya no está en tu lista.');
      return;
    }

    var recienMarcada = false;
    if (respuesta.desdeBoton &&
        estado.tomadaA(medicina.id, respuesta.dia, respuesta.minutos) == null) {
      await estado.marcarTomada(medicina.id, respuesta.dia, respuesta.minutos);
      recienMarcada = true;
    }

    final contexto = navigatorKey.currentState?.overlay?.context;
    if (contexto == null || !contexto.mounted) return;

    await mostrarConfirmacionToma(
      contexto,
      medicina: medicina,
      dia: respuesta.dia,
      minutos: respuesta.minutos,
      recienMarcada: recienMarcada,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kNombreApp,
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: mensajeroKey,
      theme: construirTema(),
      locale: const Locale('es', 'MX'),
      supportedLocales: const [Locale('es', 'MX'), Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: _respuestaInicial != null
          ? const InicioScreen()
          : const BienvenidaScreen(),
    );
  }
}
