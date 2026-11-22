import 'package:flutter/material.dart';

import '../theme.dart';
import '../utils/fechas.dart';

/// Hoja sencilla para elegir una hora con botones grandes
/// (formato de 12 horas con a. m. / p. m.).
/// Devuelve los minutos desde la medianoche, o null si se cancela.
Future<int?> elegirHora(BuildContext context, {int inicial = 8 * 60}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _SelectorHora(inicial: inicial),
  );
}

class _SelectorHora extends StatefulWidget {
  const _SelectorHora({required this.inicial});

  final int inicial;

  @override
  State<_SelectorHora> createState() => _SelectorHoraState();
}

class _SelectorHoraState extends State<_SelectorHora> {
  late int _hora12; // 1..12
  late int _minuto; // 0..55 de 5 en 5
  late bool _pm;

  static const _rapidas = [7 * 60, 8 * 60, 14 * 60, 20 * 60, 22 * 60];

  @override
  void initState() {
    super.initState();
    _poner(widget.inicial);
  }

  void _poner(int minutos) {
    final h = minutos ~/ 60;
    _pm = h >= 12;
    _hora12 = h % 12 == 0 ? 12 : h % 12;
    _minuto = (minutos % 60) - (minutos % 60) % 5;
  }

  int get _total {
    final h24 = (_hora12 % 12) + (_pm ? 12 : 0);
    return h24 * 60 + _minuto;
  }

  void _cambiarHora(int delta) => setState(() {
        _hora12 = ((_hora12 - 1 + delta) % 12 + 12) % 12 + 1;
      });

  void _cambiarMinuto(int delta) => setState(() {
        _minuto = ((_minuto + delta * 5) % 60 + 60) % 60;
      });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '¿A qué hora?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            formatoHora(_total),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w800,
              color: Cafe.cafe,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Contador(
                  etiqueta: 'Hora',
                  valor: '$_hora12',
                  alRestar: () => _cambiarHora(-1),
                  alSumar: () => _cambiarHora(1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Contador(
                  etiqueta: 'Minutos',
                  valor: _minuto.toString().padLeft(2, '0'),
                  alRestar: () => _cambiarMinuto(-1),
                  alSumar: () => _cambiarMinuto(1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: false,
                icon: Icon(Icons.wb_sunny_rounded),
                label: Text('a. m.'),
              ),
              ButtonSegment(
                value: true,
                icon: Icon(Icons.nightlight_round),
                label: Text('p. m.'),
              ),
            ],
            selected: {_pm},
            onSelectionChanged: (s) => setState(() => _pm = s.first),
          ),
          const SizedBox(height: 18),
          const Text(
            'Horas comunes',
            style: TextStyle(fontSize: 15, color: Cafe.textoSuave, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in _rapidas)
                ChoiceChip(
                  label: Text(formatoHora(r)),
                  labelStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _total == r ? Colors.white : Cafe.espresso,
                  ),
                  selected: _total == r,
                  selectedColor: Cafe.cafe,
                  backgroundColor: Colors.white,
                  showCheckmark: false,
                  side: const BorderSide(color: Cafe.borde),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  onSelected: (_) => setState(() => _poner(r)),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(_total),
                  child: const Text('Listo'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Contador extends StatelessWidget {
  const _Contador({
    required this.etiqueta,
    required this.valor,
    required this.alRestar,
    required this.alSumar,
  });

  final String etiqueta;
  final String valor;
  final VoidCallback alRestar;
  final VoidCallback alSumar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Cafe.borde, width: 1.2),
      ),
      child: Column(
        children: [
          Text(
            etiqueta,
            style: const TextStyle(fontSize: 15, color: Cafe.textoSuave, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                BotonRedondo(icono: Icons.remove_rounded, alPresionar: alRestar),
                SizedBox(
                  width: 52,
                  child: Text(
                    valor,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                  ),
                ),
                BotonRedondo(icono: Icons.add_rounded, alPresionar: alSumar),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón circular grande de + / −.
class BotonRedondo extends StatelessWidget {
  const BotonRedondo({super.key, required this.icono, required this.alPresionar});

  final IconData icono;
  final VoidCallback? alPresionar;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: alPresionar,
      style: IconButton.styleFrom(
        backgroundColor: Cafe.latte,
        foregroundColor: Cafe.espresso,
        minimumSize: const Size(48, 48),
      ),
      icon: Icon(icono, size: 26),
    );
  }
}
