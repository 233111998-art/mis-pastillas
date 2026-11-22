import 'dart:async';

import 'package:flutter/material.dart';

import '../app.dart';
import '../config.dart';
import '../data/app_state.dart';
import '../models/cita.dart';
import '../models/medicina.dart';
import '../services/notificaciones.dart';
import '../theme.dart';
import '../utils/fechas.dart';
import '../widgets/cita_widgets.dart';
import '../widgets/comunes.dart';
import '../widgets/confirmar_toma_sheet.dart';
import 'registro_screen.dart';

class HoyScreen extends StatefulWidget {
  const HoyScreen({super.key, required this.alAgregar});

  final VoidCallback alAgregar;

  @override
  State<HoyScreen> createState() => _HoyScreenState();
}

class _HoyScreenState extends State<HoyScreen> {
  Timer? _reloj;

  @override
  void initState() {
    super.initState();
    // Revisa seguido si alguna toma ya llegó a su hora (para desbloquear el botón).
    _reloj = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

  Future<void> _marcar(Dosis d) async {
    final ok = await AppState.instance.marcarTomada(d.medicina.id, d.dia, d.minutos);
    if (!ok) {
      mostrarMensaje('Todavía no es hora de esta toma.');
      return;
    }
    final hora = AppState.instance.tomadaA(d.medicina.id, d.dia, d.minutos);
    mostrarMensaje(
      hora == null
          ? 'Toma registrada'
          : '✓ Toma de ${d.medicina.nombre} registrada a las ${formatoHoraDe(hora)}',
      accion: SnackBarAction(
        label: 'Deshacer',
        onPressed: () => AppState.instance.desmarcar(d.medicina.id, d.dia, d.minutos),
      ),
    );
  }

  void _abrir(Dosis d) {
    mostrarConfirmacionToma(
      context,
      medicina: d.medicina,
      dia: d.dia,
      minutos: d.minutos,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final ahora = DateTime.now();
        final estado = AppState.instance;
        final dosis = estado.dosisDelDia(ahora);
        final tomadas = dosis.where((d) => d.tomadaA != null).length;
        final proximas = estado
            .proximasCitas(ahora)
            .where((c) => diasEntre(ahora, c.fecha) <= 7)
            .toList();
        final Cita? proxima = proximas.isEmpty ? null : proximas.first;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _Encabezado(
                ahora: ahora,
                total: dosis.length,
                tomadas: tomadas,
              ),
            ),
            if (proxima != null)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: TarjetaCita(
                    cita: proxima,
                    ahora: ahora,
                    etiquetaArriba: proximas.length > 1
                        ? 'Próxima cita (+${proximas.length - 1} esta semana)'
                        : 'Próxima cita',
                    alTocar: () {
                      estado.pestana.value = AppState.pestanaAgenda;
                      estado.citaEnfocada.value = proxima.id;
                    },
                  ),
                ),
              ),
            if (estado.medicinas.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: EstadoVacio(
                    icono: Icons.medication_rounded,
                    titulo: 'Aún no tienes pastillas',
                    mensaje: 'Agrega la primera y te avisaré cuando sea hora de tomarla.',
                    accion: FilledButton.icon(
                      onPressed: widget.alAgregar,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Agregar pastilla'),
                    ),
                  ),
                ),
              )
            else if (dosis.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: EstadoVacio(
                    icono: Icons.wb_sunny_rounded,
                    titulo: 'Hoy no te toca ninguna',
                    mensaje: 'Disfruta tu día. Revisa la pestaña "Pastillas" para ver las próximas.',
                  ),
                ),
              )
            else ...[
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 22, 20, 0),
                sliver: SliverToBoxAdapter(child: TituloSeccion('Tus tomas de hoy')),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                sliver: SliverList.separated(
                  itemCount: dosis.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => TarjetaDosis(
                    dosis: dosis[i],
                    ahora: ahora,
                    alMarcar: () => _marcar(dosis[i]),
                    alTocar: () => _abrir(dosis[i]),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({
    required this.ahora,
    required this.total,
    required this.tomadas,
  });

  final DateTime ahora;
  final int total;
  final int tomadas;

  String get _mensaje {
    if (total == 0) return 'Nada pendiente por hoy';
    if (tomadas == total) return '¡Completaste todas las de hoy! 🎉';
    if (tomadas == 0) return 'Aún no registras ninguna';
    return '¡Vas muy bien, sigue así!';
  }

  @override
  Widget build(BuildContext context) {
    final avance = total == 0 ? 0.0 : tomadas / total;
    final arriba = MediaQuery.paddingOf(context).top;

    return Container(
      padding: EdgeInsets.fromLTRB(24, arriba + 18, 16, 26),
      decoration: const BoxDecoration(
        gradient: Cafe.degradado,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${saludo(ahora)},',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Cafe.latte.withValues(alpha: 0.9),
                      ),
                    ),
                    Text(
                      AppState.instance.nombre,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fechaLarga(ahora),
                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Ajustes',
                onPressed: () => mostrarAjustesAvisos(context),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.14),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(52, 52),
                ),
                icon: const Icon(Icons.settings_rounded, size: 26),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: avance),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (_, valor, _) => Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: valor,
                          strokeWidth: 8,
                          strokeCap: StrokeCap.round,
                          backgroundColor: Colors.white.withValues(alpha: 0.18),
                          valueColor: const AlwaysStoppedAnimation(Cafe.caramelo),
                        ),
                        Center(
                          child: Text(
                            '$tomadas/$total',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _mensaje,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        total == 1
                            ? '$tomadas de 1 toma registrada'
                            : '$tomadas de $total tomas registradas',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.78),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de una toma del día.
class TarjetaDosis extends StatelessWidget {
  const TarjetaDosis({
    super.key,
    required this.dosis,
    required this.ahora,
    required this.alMarcar,
    required this.alTocar,
  });

  final Dosis dosis;
  final DateTime ahora;
  final VoidCallback alMarcar;
  final VoidCallback alTocar;

  int get _minutosDesbloqueo {
    final m = dosis.minutos - kMinutosAntesPermitidos;
    return m < 0 ? 0 : m;
  }

  @override
  Widget build(BuildContext context) {
    final m = dosis.medicina;
    final estado = dosis.estado(ahora);
    final tomada = estado == EstadoDosis.tomada;
    final atrasada = estado == EstadoDosis.atrasada;

    return Tarjeta(
      onTap: alTocar,
      color: tomada ? const Color(0xFFF1F5EC) : Cafe.espuma,
      borde: tomada
          ? Cafe.verde.withValues(alpha: 0.35)
          : atrasada
              ? Cafe.ambar.withValues(alpha: 0.55)
              : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconoPastilla(color: Cafe.colorPastilla(m.color)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.nombre,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    if (dosis.dosisTexto.isNotEmpty)
                      Text(
                        m.cambiaPorDia ? 'Hoy toca: ${dosis.dosisTexto}' : dosis.dosisTexto,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: m.cambiaPorDia ? Cafe.caramelo : Cafe.cafeMedio,
                        ),
                      ),
                    if (m.notas.trim().isNotEmpty)
                      Text(
                        m.notas.trim(),
                        style: const TextStyle(fontSize: 15, color: Cafe.textoSuave),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatoHora(dosis.minutos),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  if (!m.esPermanente)
                    const Text(
                      'Temporal',
                      style: TextStyle(fontSize: 13, color: Cafe.textoSuave),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (tomada)
            Align(
              alignment: Alignment.centerLeft,
              child: Etiqueta(
                icono: Icons.check_circle_rounded,
                texto: 'Tomada a las ${formatoHoraDe(dosis.tomadaA!)}',
                color: Cafe.verde,
                fondo: Cafe.verdeClaro,
              ),
            )
          else ...[
            Align(
              alignment: Alignment.centerLeft,
              child: atrasada
                  ? const Etiqueta(
                      icono: Icons.schedule_rounded,
                      texto: 'Ya pasó la hora',
                      color: Cafe.ambar,
                      fondo: Cafe.ambarClaro,
                    )
                  : const Etiqueta(
                      icono: Icons.hourglass_top_rounded,
                      texto: 'Pendiente',
                      color: Cafe.cafe,
                      fondo: Cafe.latte,
                    ),
            ),
            const SizedBox(height: 12),
            if (atrasada)
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Cafe.cafe,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                ),
                onPressed: alMarcar,
                icon: const Icon(Icons.check_rounded, size: 26),
                label: const Text('Ya me la tomé'),
              )
            else
              // Bloqueado hasta la hora de la toma.
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  disabledBackgroundColor: const Color(0xFFEFE6DC),
                  disabledForegroundColor: Cafe.textoSuave,
                  minimumSize: const Size.fromHeight(56),
                ),
                onPressed: null,
                icon: const Icon(Icons.lock_clock_rounded, size: 24),
                label: Text('Se activa a las ${formatoHora(_minutosDesbloqueo)}'),
              ),
          ],
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Ajustes de avisos
// -----------------------------------------------------------------------------

Future<void> mostrarAjustesAvisos(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _AjustesAvisos(),
  );
}

class _AjustesAvisos extends StatefulWidget {
  const _AjustesAvisos();

  @override
  State<_AjustesAvisos> createState() => _AjustesAvisosState();
}

class _AjustesAvisosState extends State<_AjustesAvisos> {
  bool? _permitidos;
  bool? _exactos;

  final _avisos = Notificaciones.instance;

  @override
  void initState() {
    super.initState();
    _revisar();
  }

  Future<void> _revisar() async {
    bool permitidos;
    bool exactos;
    try {
      permitidos = await _avisos.avisosActivados();
      exactos = await _avisos.alarmasExactasPermitidas();
    } catch (_) {
      permitidos = false;
      exactos = false;
    }
    if (!mounted) return;
    setState(() {
      _permitidos = permitidos;
      _exactos = exactos;
    });
  }

  void _cambiarNombre() {
    final nav = Navigator.of(context);
    nav.pop(); // cierra Ajustes
    nav.push(
      MaterialPageRoute<void>(builder: (_) => const RegistroScreen()),
    );
  }

  Future<void> _activarAvisos() async {
    final ok = await _avisos.pedirPermisos();
    await _revisar();
    if (!ok) {
      mostrarMensaje('Actívalos en Ajustes del teléfono > Apps > $kNombreApp > Notificaciones');
    }
  }

  Future<void> _activarExactos() async {
    await _avisos.pedirAlarmasExactas();
    mostrarMensaje('Activa el permiso y vuelve a abrir la app.');
  }

  Future<void> _probarAhora() async {
    await _avisos.mostrarPrueba();
    mostrarMensaje('Listo, revisa tus notificaciones.');
  }

  Future<void> _probarEnUnMinuto() async {
    await _avisos.programarPruebaEnUnMinuto();
    mostrarMensaje('Te llegará un aviso en 1 minuto. Puedes salir de la app.');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Ajustes', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 14),
          Tarjeta(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            onTap: _cambiarNombre,
            child: Row(
              children: [
                const Icon(Icons.person_rounded, color: Cafe.cafe, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tu nombre',
                        style: TextStyle(fontSize: 14, color: Cafe.textoSuave),
                      ),
                      Text(
                        AppState.instance.nombre,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                TextButton(onPressed: _cambiarNombre, child: const Text('Cambiar')),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text('Avisos', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          const Text(
            'Revisa que todo esté listo para que te lleguen los recordatorios.',
            style: TextStyle(fontSize: 16, color: Cafe.textoSuave),
          ),
          const SizedBox(height: 14),
          _fila(
            icono: Icons.notifications_rounded,
            titulo: 'Permiso para avisar',
            ok: _permitidos,
            textoBoton: 'Activar',
            alPresionar: _activarAvisos,
          ),
          const SizedBox(height: 10),
          _fila(
            icono: Icons.alarm_on_rounded,
            titulo: 'Avisos a la hora exacta',
            ok: _exactos,
            textoBoton: 'Permitir',
            alPresionar: _activarExactos,
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: _probarAhora,
            icon: const Icon(Icons.notifications_rounded),
            label: const Text('Probar un aviso ahora'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _probarEnUnMinuto,
            icon: const Icon(Icons.timer_rounded),
            label: const Text('Probar en 1 minuto'),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Cafe.ambarClaro,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.battery_alert_rounded, color: Cafe.ambar),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Si los avisos no llegan, entra a Ajustes del teléfono > Batería '
                    'y quita el ahorro de batería para esta app.',
                    style: TextStyle(fontSize: 15, color: Cafe.espresso),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fila({
    required IconData icono,
    required String titulo,
    required bool? ok,
    required String textoBoton,
    required VoidCallback alPresionar,
  }) {
    return Tarjeta(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icono, color: Cafe.cafe, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
          if (ok == null)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          else if (ok)
            const Etiqueta(
              icono: Icons.check_rounded,
              texto: 'Listo',
              color: Cafe.verde,
              fondo: Cafe.verdeClaro,
            )
          else
            TextButton(onPressed: alPresionar, child: Text(textoBoton)),
        ],
      ),
    );
  }
}
