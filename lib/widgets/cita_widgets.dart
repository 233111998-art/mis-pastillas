import 'package:flutter/material.dart';

import '../app.dart';
import '../config.dart';
import '../data/app_state.dart';
import '../models/cita.dart';
import '../screens/editar_cita_screen.dart';
import '../theme.dart';
import '../utils/fechas.dart';
import 'comunes.dart';

/// Colores e iconos de cada tipo de cita.
class EstiloCita {
  EstiloCita._();

  static Color color(TipoCita tipo) =>
      tipo == TipoCita.consulta ? Cafe.cafe : const Color(0xFF5F7486);

  static IconData icono(TipoCita tipo) =>
      tipo == TipoCita.consulta ? Icons.medical_services_rounded : Icons.science_rounded;
}

/// Tarjeta de una consulta o laboratorio.
class TarjetaCita extends StatelessWidget {
  const TarjetaCita({
    super.key,
    required this.cita,
    required this.ahora,
    this.alTocar,
    this.etiquetaArriba,
  });

  final Cita cita;
  final DateTime ahora;
  final VoidCallback? alTocar;

  /// Texto pequeño arriba, por ejemplo "Próxima cita".
  final String? etiquetaArriba;

  @override
  Widget build(BuildContext context) {
    final color = EstiloCita.color(cita.tipo);
    final paso = cita.yaPaso(ahora);

    return Tarjeta(
      onTap: alTocar,
      color: paso ? const Color(0xFFF3ECE4) : Cafe.espuma,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (etiquetaArriba != null) ...[
            Text(
              etiquetaArriba!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Cafe.textoSuave,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: paso ? 0.08 : 0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  EstiloCita.icono(cita.tipo),
                  color: paso ? Cafe.textoSuave : color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cita.titulo,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: paso ? Cafe.textoSuave : Cafe.espresso,
                      ),
                    ),
                    Text(
                      cita.cuando(ahora),
                      style: const TextStyle(fontSize: 16, color: Cafe.cafeMedio),
                    ),
                    if (cita.lugar.trim().isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.place_rounded, size: 16, color: Cafe.textoSuave),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              cita.lugar.trim(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 15, color: Cafe.textoSuave),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Etiqueta(
                icono: EstiloCita.icono(cita.tipo),
                texto: cita.tipo.nombre,
                color: color,
                fondo: color.withValues(alpha: 0.12),
              ),
              if (cita.esLaboratorio && cita.ayunas)
                const Etiqueta(
                  icono: Icons.no_food_rounded,
                  texto: 'En ayunas',
                  color: Cafe.ambar,
                  fondo: Cafe.ambarClaro,
                ),
              if (paso)
                const Etiqueta(
                  icono: Icons.history_rounded,
                  texto: 'Ya pasó',
                  color: Cafe.textoSuave,
                  fondo: Cafe.latte,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Hoja con todos los datos de la cita y botones para editar o quitar.
Future<void> mostrarDetalleCita(BuildContext context, Cita cita) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _DetalleCita(cita: cita),
  );
}

class _DetalleCita extends StatelessWidget {
  const _DetalleCita({required this.cita});

  final Cita cita;

  Future<void> _quitar(BuildContext context) async {
    final nav = Navigator.of(context);
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: Text('¿Quitar "${cita.titulo}"?'),
        content: const Text(
          'Se borrará de tu agenda y ya no te llegarán sus avisos.',
          style: TextStyle(fontSize: 17),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Cafe.rojo,
              minimumSize: const Size(100, 50),
            ),
            onPressed: () => Navigator.of(contexto).pop(true),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    nav.pop();
    await AppState.instance.eliminarCita(cita.id);
    mostrarMensaje('Se quitó "${cita.titulo}" de tu agenda.');
  }

  void _editar(BuildContext context) {
    final nav = Navigator.of(context);
    nav.pop();
    nav.push(MaterialPageRoute<void>(builder: (_) => EditarCitaScreen(cita: cita)));
  }

  @override
  Widget build(BuildContext context) {
    final ahora = DateTime.now();
    final color = EstiloCita.color(cita.tipo);

    final avisos = <String>[
      if (cita.avisoDiaAntes) 'Un día antes a las ${formatoHora(kHoraAvisoDiaAntes)}',
      if (cita.avisoHorasAntes > 0)
        cita.avisoHorasAntes == 1 ? '1 hora antes' : '${cita.avisoHorasAntes} horas antes',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(EstiloCita.icono(cita.tipo), size: 44, color: color),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            cita.titulo,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            cita.tipo.nombre,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 18),
          _Dato(
            icono: Icons.event_rounded,
            texto: '${fechaLarga(cita.fecha)} · ${formatoHoraDe(cita.fecha)}',
            detalle: fechaRelativa(cita.fecha, ahora) == fechaLarga(cita.fecha)
                ? null
                : fechaRelativa(cita.fecha, ahora),
          ),
          if (cita.lugar.trim().isNotEmpty)
            _Dato(icono: Icons.place_rounded, texto: cita.lugar.trim()),
          if (cita.esLaboratorio && cita.ayunas)
            const _Dato(
              icono: Icons.no_food_rounded,
              texto: 'Ir en ayunas',
              color: Cafe.ambar,
            ),
          if (cita.notas.trim().isNotEmpty)
            _Dato(icono: Icons.sticky_note_2_rounded, texto: cita.notas.trim()),
          _Dato(
            icono: Icons.notifications_rounded,
            texto: avisos.isEmpty ? 'Sin avisos' : 'Aviso: ${avisos.join(' y ')}',
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => _editar(context),
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Editar'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Cafe.rojo,
              side: const BorderSide(color: Cafe.rojo, width: 1.4),
            ),
            onPressed: () => _quitar(context),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Quitar de la agenda'),
          ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({
    required this.icono,
    required this.texto,
    this.detalle,
    this.color = Cafe.cafe,
  });

  final IconData icono;
  final String texto;
  final String? detalle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: color, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  texto,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                if (detalle != null)
                  Text(
                    detalle!,
                    style: const TextStyle(fontSize: 15, color: Cafe.textoSuave),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
