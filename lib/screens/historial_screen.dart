import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../models/medicina.dart';
import '../theme.dart';
import '../utils/fechas.dart';
import '../widgets/comunes.dart';
import '../widgets/encabezado.dart';

/// Últimos días: qué se tomó y a qué hora.
class HistorialScreen extends StatelessWidget {
  const HistorialScreen({super.key});

  static const _diasAMostrar = 14;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final ahora = DateTime.now();
        final hoy = soloFecha(ahora);
        final dias = <(DateTime, List<Dosis>)>[];
        for (var i = 0; i < _diasAMostrar; i++) {
          final dia = sumarDias(hoy, -i);
          final dosis = AppState.instance.dosisDelDia(dia);
          if (dosis.isNotEmpty) dias.add((dia, dosis));
        }

        return CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: EncabezadoPantalla(
                titulo: 'Historial',
                subtitulo: 'Revisa si ya te tomaste tus pastillas',
                icono: Icons.history_rounded,
              ),
            ),
            if (dias.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: EstadoVacio(
                    icono: Icons.event_note_rounded,
                    titulo: 'Todavía no hay historial',
                    mensaje: 'Aquí verás cada toma que registres, con la hora exacta.',
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 40),
                sliver: SliverList.separated(
                  itemCount: dias.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, i) => _TarjetaDia(
                    dia: dias[i].$1,
                    dosis: dias[i].$2,
                    ahora: ahora,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TarjetaDia extends StatelessWidget {
  const _TarjetaDia({required this.dia, required this.dosis, required this.ahora});

  final DateTime dia;
  final List<Dosis> dosis;
  final DateTime ahora;

  @override
  Widget build(BuildContext context) {
    final tomadas = dosis.where((d) => d.tomadaA != null).length;
    final completo = tomadas == dosis.length;
    final titulo = fechaRelativa(dia, ahora);

    return Tarjeta(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    if (titulo == 'Hoy' || titulo == 'Ayer')
                      Text(
                        fechaLarga(dia),
                        style: const TextStyle(fontSize: 14, color: Cafe.textoSuave),
                      ),
                  ],
                ),
              ),
              Etiqueta(
                icono: completo ? Icons.check_circle_rounded : Icons.donut_large_rounded,
                texto: '$tomadas de ${dosis.length}',
                color: completo ? Cafe.verde : Cafe.cafe,
                fondo: completo ? Cafe.verdeClaro : Cafe.latte,
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final d in dosis) _FilaDosis(dosis: d, ahora: ahora),
        ],
      ),
    );
  }
}

class _FilaDosis extends StatelessWidget {
  const _FilaDosis({required this.dosis, required this.ahora});

  final Dosis dosis;
  final DateTime ahora;

  @override
  Widget build(BuildContext context) {
    final estado = dosis.estado(ahora);
    final (IconData icono, Color color, String texto) = switch (estado) {
      EstadoDosis.tomada => (
          Icons.check_circle_rounded,
          Cafe.verde,
          'Tomada ${formatoHoraDe(dosis.tomadaA!)}',
        ),
      EstadoDosis.pendiente => (Icons.hourglass_top_rounded, Cafe.textoSuave, 'Pendiente'),
      EstadoDosis.atrasada => (Icons.schedule_rounded, Cafe.ambar, 'Sin registrar'),
      EstadoDosis.sinRegistro => (Icons.cancel_rounded, Cafe.rojo, 'No registrada'),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              formatoHora(dosis.minutos),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Cafe.textoSuave,
              ),
            ),
          ),
          Expanded(
            child: Text(
              dosis.medicina.titulo,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          Icon(icono, color: color, size: 20),
          const SizedBox(width: 4),
          Text(
            texto,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}
