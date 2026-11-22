import 'package:flutter/material.dart';

import '../app.dart';
import '../data/app_state.dart';
import '../models/medicina.dart';
import '../theme.dart';
import '../utils/fechas.dart';
import '../widgets/comunes.dart';
import '../widgets/encabezado.dart';
import 'editar_pastilla_screen.dart';

class MisPastillasScreen extends StatelessWidget {
  const MisPastillasScreen({super.key, required this.alAgregar});

  final VoidCallback alAgregar;

  void _editar(BuildContext context, Medicina m) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => EditarPastillaScreen(medicina: m)),
    );
  }

  Future<void> _eliminar(BuildContext context, Medicina m) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: Text('¿Quitar ${m.nombre}?'),
        content: const Text(
          'Ya no te llegarán avisos de esta pastilla y se borrará su historial.',
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
    if (confirmar == true) {
      await AppState.instance.eliminarMedicina(m.id);
      mostrarMensaje('${m.nombre} se quitó de tu lista.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final hoy = DateTime.now();
        final todas = AppState.instance.medicinas;
        int porNombre(Medicina a, Medicina b) =>
            a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());

        final permanentes = todas.where((m) => m.esPermanente).toList()..sort(porNombre);
        final temporales = todas
            .where((m) => !m.esPermanente && !m.terminadaEn(hoy))
            .toList()
          ..sort(porNombre);
        final terminadas = todas.where((m) => m.terminadaEn(hoy)).toList()..sort(porNombre);

        final activas = permanentes.length + temporales.length;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: EncabezadoPantalla(
                titulo: 'Mis pastillas',
                subtitulo: activas == 0
                    ? 'Agrega las que tomas'
                    : activas == 1
                        ? '1 pastilla activa'
                        : '$activas pastillas activas',
                icono: Icons.medication_rounded,
              ),
            ),
            if (todas.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: EstadoVacio(
                    icono: Icons.medication_liquid_rounded,
                    titulo: 'Tu lista está vacía',
                    mensaje: 'Puedes agregar pastillas que tomas para siempre '
                        'o solo por unos días.',
                    accion: FilledButton.icon(
                      onPressed: alAgregar,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Agregar pastilla'),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 120),
                sliver: SliverList.list(
                  children: [
                    if (permanentes.isNotEmpty) ...[
                      const TituloSeccion('Para siempre'),
                      for (final m in permanentes)
                        _TarjetaMedicina(
                          medicina: m,
                          hoy: hoy,
                          alEditar: () => _editar(context, m),
                          alEliminar: () => _eliminar(context, m),
                        ),
                      const SizedBox(height: 14),
                    ],
                    if (temporales.isNotEmpty) ...[
                      const TituloSeccion('Por unos días'),
                      for (final m in temporales)
                        _TarjetaMedicina(
                          medicina: m,
                          hoy: hoy,
                          alEditar: () => _editar(context, m),
                          alEliminar: () => _eliminar(context, m),
                        ),
                      const SizedBox(height: 14),
                    ],
                    if (terminadas.isNotEmpty) ...[
                      const TituloSeccion('Ya terminadas'),
                      for (final m in terminadas)
                        _TarjetaMedicina(
                          medicina: m,
                          hoy: hoy,
                          alEditar: () => _editar(context, m),
                          alEliminar: () => _eliminar(context, m),
                        ),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TarjetaMedicina extends StatelessWidget {
  const _TarjetaMedicina({
    required this.medicina,
    required this.hoy,
    required this.alEditar,
    required this.alEliminar,
  });

  final Medicina medicina;
  final DateTime hoy;
  final VoidCallback alEditar;
  final VoidCallback alEliminar;

  String get _descripcionDuracion {
    final m = medicina;
    if (m.esPermanente) return 'Todos los días';
    final fin = m.fechaFin!;
    if (m.terminadaEn(hoy)) return 'Terminó el ${fechaCorta(fin)}';
    if (m.porEmpezarEn(hoy)) {
      return 'Empieza el ${fechaCorta(m.fechaInicio)} · ${m.dias} días';
    }
    final quedan = m.diasRestantes(hoy) ?? 0;
    final texto = quedan == 1 ? 'Hoy es el último día' : 'Quedan $quedan días';
    return '$texto · termina el ${fechaCorta(fin)}';
  }

  @override
  Widget build(BuildContext context) {
    final m = medicina;
    final terminada = m.terminadaEn(hoy);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Tarjeta(
        onTap: alEditar,
        color: terminada ? const Color(0xFFF3ECE4) : Cafe.espuma,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconoPastilla(color: Cafe.colorPastilla(m.color), apagado: terminada),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.titulo,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: terminada ? Cafe.textoSuave : Cafe.espresso,
                        ),
                      ),
                      Text(
                        _descripcionDuracion,
                        style: const TextStyle(fontSize: 15, color: Cafe.textoSuave),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Opciones',
                  icon: const Icon(Icons.more_vert_rounded, color: Cafe.textoSuave),
                  color: Cafe.espuma,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  onSelected: (opcion) {
                    if (opcion == 'editar') alEditar();
                    if (opcion == 'quitar') alEliminar();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'editar',
                      child: ListTile(
                        leading: Icon(Icons.edit_rounded),
                        title: Text('Editar'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'quitar',
                      child: ListTile(
                        leading: Icon(Icons.delete_outline_rounded, color: Cafe.rojo),
                        title: Text('Quitar', style: TextStyle(color: Cafe.rojo)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Etiqueta(
                  icono: m.esPermanente ? Icons.all_inclusive_rounded : Icons.date_range_rounded,
                  texto: m.esPermanente ? 'Para siempre' : 'Por ${m.dias} días',
                  color: Cafe.cafe,
                  fondo: Cafe.latte,
                ),
                for (final minutos in m.horarios)
                  Etiqueta(
                    icono: Icons.schedule_rounded,
                    texto: formatoHora(minutos),
                    color: Cafe.espresso,
                    fondo: const Color(0xFFF3E9DE),
                  ),
              ],
            ),
            if (m.notas.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                m.notas.trim(),
                style: const TextStyle(fontSize: 15, color: Cafe.cafeMedio),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
