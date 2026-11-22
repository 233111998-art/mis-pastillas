import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../data/app_state.dart';
import '../services/notificaciones.dart';
import '../theme.dart';
import '../utils/fechas.dart';

class BienvenidaScreen extends StatefulWidget {
  const BienvenidaScreen({super.key});

  @override
  State<BienvenidaScreen> createState() => _BienvenidaScreenState();
}

class _BienvenidaScreenState extends State<BienvenidaScreen> {
  bool _entrando = false;

  Future<void> _comenzar() async {
    if (_entrando) return;
    setState(() => _entrando = true);

    // La primera vez Android/iPhone preguntan si la app puede mandar avisos.
    try {
      await Notificaciones.instance.pedirPermisos();
    } catch (_) {}

    if (!mounted) return;
    Navigator.of(context).pushReplacement(crearRutaInicio());
  }

  String _resumenDeHoy() {
    final dosis = AppState.instance.dosisDelDia(DateTime.now());
    if (AppState.instance.medicinas.isEmpty) {
      return 'Empecemos agregando tus pastillas';
    }
    if (dosis.isEmpty) return 'Hoy no te toca ninguna pastilla';
    final faltan = dosis.where((d) => d.tomadaA == null).length;
    if (faltan == 0) return '¡Ya registraste todas las de hoy!';
    return faltan == 1
        ? 'Hoy te falta 1 toma por registrar'
        : 'Hoy te faltan $faltan tomas por registrar';
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: estiloBarraClara,
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(gradient: Cafe.degradado),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Círculos decorativos de fondo.
              Positioned(
                top: -80,
                right: -60,
                child: _burbuja(240, Cafe.caramelo.withValues(alpha: 0.22)),
              ),
              Positioned(
                bottom: 120,
                left: -90,
                child: _burbuja(220, Cafe.latte.withValues(alpha: 0.10)),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, limites) => SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: math.max(0.0, limites.maxHeight - 52),
                      ),
                      child: IntrinsicHeight(
                        child: _Aparecer(child: _contenido()),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contenido() {
    final ahora = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(flex: 2),
        Container(
          width: 104,
          height: 104,
          decoration: BoxDecoration(
            color: Cafe.crema,
            borderRadius: BorderRadius.circular(34),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: const Icon(Icons.medication_rounded, size: 60, color: Cafe.cafe),
        ),
        const SizedBox(height: 36),
        Text(
          '${saludo(ahora)},',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Cafe.latte.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '¡${AppState.instance.palabraBienvenida},\n${AppState.instance.nombre}!',
          style: const TextStyle(
            fontSize: 46,
            height: 1.05,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Aquí llevamos el control de tus pastillas '
          'para que no se te olvide ninguna.',
          style: TextStyle(
            fontSize: 19,
            height: 1.35,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 26),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.today_rounded, color: Cafe.latte),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  '${fechaLarga(ahora)} · ${_resumenDeHoy()}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Spacer(flex: 3),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Cafe.crema,
              foregroundColor: Cafe.espresso,
              minimumSize: const Size.fromHeight(64),
            ),
            onPressed: _entrando ? null : _comenzar,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Comenzar', style: TextStyle(fontSize: 20)),
                SizedBox(width: 10),
                Icon(Icons.arrow_forward_rounded, size: 26),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _burbuja(double tamano, Color color) => Container(
        width: tamano,
        height: tamano,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

/// Aparece suavemente desde abajo.
class _Aparecer extends StatelessWidget {
  const _Aparecer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (_, t, hijo) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 30 * (1 - t)), child: hijo),
      ),
      child: child,
    );
  }
}
