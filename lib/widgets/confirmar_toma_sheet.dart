import 'package:flutter/material.dart';

import '../config.dart';
import '../data/app_state.dart';
import '../models/medicina.dart';
import '../theme.dart';
import '../utils/fechas.dart';
import 'comunes.dart';

/// Abre la hoja que pregunta "¿Ya te tomaste tu pastilla?" o que avisa
/// "Ya te la tomaste" si esa dosis ya estaba registrada.
Future<void> mostrarConfirmacionToma(
  BuildContext context, {
  required Medicina medicina,
  required DateTime dia,
  required int minutos,
  bool recienMarcada = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => ConfirmarTomaSheet(
      medicina: medicina,
      dia: dia,
      minutos: minutos,
      recienMarcada: recienMarcada,
    ),
  );
}

enum _Vista { pregunta, recienMarcada, yaTomada }

class ConfirmarTomaSheet extends StatefulWidget {
  const ConfirmarTomaSheet({
    super.key,
    required this.medicina,
    required this.dia,
    required this.minutos,
    this.recienMarcada = false,
  });

  final Medicina medicina;
  final DateTime dia;
  final int minutos;

  /// true si se acaba de registrar con el botón del aviso.
  final bool recienMarcada;

  @override
  State<ConfirmarTomaSheet> createState() => _ConfirmarTomaSheetState();
}

class _ConfirmarTomaSheetState extends State<ConfirmarTomaSheet> {
  late _Vista _vista;

  AppState get _estado => AppState.instance;

  DateTime? get _tomadaA =>
      _estado.tomadaA(widget.medicina.id, widget.dia, widget.minutos);

  @override
  void initState() {
    super.initState();
    if (widget.recienMarcada) {
      _vista = _Vista.recienMarcada;
    } else if (_tomadaA != null) {
      _vista = _Vista.yaTomada;
    } else {
      _vista = _Vista.pregunta;
    }
  }

  Future<void> _marcar() async {
    await _estado.marcarTomada(widget.medicina.id, widget.dia, widget.minutos);
    if (!mounted) return;
    setState(() => _vista = _Vista.recienMarcada);
  }

  Future<void> _deshacer() async {
    await _estado.desmarcar(widget.medicina.id, widget.dia, widget.minutos);
    if (!mounted) return;
    setState(() => _vista = _Vista.pregunta);
  }

  String get _cuandoEsLaDosis {
    final hora = formatoHora(widget.minutos);
    final ahora = DateTime.now();
    final dia = fechaRelativa(widget.dia, ahora);
    return 'Toma de las $hora · $dia';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (hijo, animacion) => FadeTransition(
          opacity: animacion,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(animacion),
            child: hijo,
          ),
        ),
        child: switch (_vista) {
          _Vista.pregunta => _pregunta(context),
          _Vista.recienMarcada => _listo(context),
          _Vista.yaTomada => _yaTomada(context),
        },
      ),
    );
  }

  Widget _resumen() {
    final m = widget.medicina;
    return Tarjeta(
      color: Colors.white,
      child: Row(
        children: [
          IconoPastilla(color: Cafe.colorPastilla(m.color), tamano: 58),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.titulo,
                  style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  _cuandoEsLaDosis,
                  style: const TextStyle(fontSize: 16, color: Cafe.textoSuave),
                ),
                if (m.notas.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    m.notas.trim(),
                    style: const TextStyle(fontSize: 15, color: Cafe.cafeMedio),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circulo(IconData icono, Color color, Color fondo) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.elasticOut,
      builder: (_, escala, hijo) => Transform.scale(scale: escala, child: hijo),
      child: Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(color: fondo, shape: BoxShape.circle),
        child: Icon(icono, size: 52, color: color),
      ),
    );
  }

  Widget _pregunta(BuildContext context) {
    return Column(
      key: const ValueKey('pregunta'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '¿Ya te tomaste tu pastilla?',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 20),
        _resumen(),
        const SizedBox(height: 24),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Cafe.verde,
            minimumSize: const Size.fromHeight(64),
          ),
          onPressed: _marcar,
          icon: const Icon(Icons.check_circle_rounded, size: 28),
          label: const Text('Sí, ya me la tomé', style: TextStyle(fontSize: 20)),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Todavía no'),
        ),
      ],
    );
  }

  Widget _listo(BuildContext context) {
    final hora = _tomadaA;
    return Column(
      key: const ValueKey('listo'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: _circulo(Icons.check_rounded, Cafe.verde, Cafe.verdeClaro)),
        const SizedBox(height: 18),
        Text(
          '¡Listo, $kNombreUsuaria!',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          hora == null
              ? 'Quedó registrada tu toma de ${widget.medicina.titulo}.'
              : 'Quedó registrada tu toma de ${widget.medicina.titulo} '
                  'a las ${formatoHoraDe(hora)}.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, color: Cafe.textoSuave),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Perfecto'),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: _deshacer,
          child: const Text('Deshacer, todavía no me la tomo'),
        ),
      ],
    );
  }

  Widget _yaTomada(BuildContext context) {
    final hora = _tomadaA;
    final ahora = DateTime.now();
    final cuando = hora == null
        ? ''
        : mismoDia(hora, ahora)
            ? 'hoy a las ${formatoHoraDe(hora)}'
            : '${fechaRelativa(hora, ahora).toLowerCase()} a las ${formatoHoraDe(hora)}';

    return Column(
      key: const ValueKey('yaTomada'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: _circulo(Icons.verified_rounded, Cafe.verde, Cafe.verdeClaro)),
        const SizedBox(height: 18),
        Text(
          'Ya te la tomaste',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'La registraste $cuando.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, color: Cafe.textoSuave),
        ),
        const SizedBox(height: 18),
        _resumen(),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Cafe.ambarClaro,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_rounded, color: Cafe.ambar, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No necesitas tomarla otra vez.',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Cafe.espresso,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Entendido'),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: _deshacer,
          child: const Text('Me equivoqué, no me la he tomado'),
        ),
      ],
    );
  }
}
