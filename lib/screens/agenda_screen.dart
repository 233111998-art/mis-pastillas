import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../models/cita.dart';
import '../theme.dart';
import '../utils/fechas.dart';
import '../widgets/cita_widgets.dart';
import '../widgets/comunes.dart';
import '../widgets/encabezado.dart';

/// Agenda: calendario con consultas y laboratorios.
class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key, required this.alAgregar, this.alCambiarDia});

  /// Abre el formulario de cita nueva con el día sugerido.
  final void Function(DateTime dia) alAgregar;

  /// Avisa qué día está elegido en el calendario.
  final ValueChanged<DateTime>? alCambiarDia;

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  late DateTime _mes; // día 1 del mes visible
  late DateTime _elegido;
  TipoCita? _filtro; // null = todas

  final _estado = AppState.instance;

  @override
  void initState() {
    super.initState();
    final hoy = soloFecha(DateTime.now());
    _elegido = hoy;
    _mes = DateTime(hoy.year, hoy.month);
    _estado.citaEnfocada.addListener(_enfocarCita);
    // Por si la app se abrió desde el aviso de una cita.
    WidgetsBinding.instance.addPostFrameCallback((_) => _enfocarCita());
  }

  @override
  void dispose() {
    _estado.citaEnfocada.removeListener(_enfocarCita);
    super.dispose();
  }

  /// Muestra la cita pedida (por ejemplo al tocar su aviso).
  void _enfocarCita() {
    final id = _estado.citaEnfocada.value;
    if (id == null || !mounted) return;
    _estado.citaEnfocada.value = null;
    final cita = _estado.buscarCita(id);
    if (cita == null) return;
    _elegir(cita.fecha);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) mostrarDetalleCita(context, cita);
    });
  }

  bool _pasaFiltro(Cita c) => _filtro == null || c.tipo == _filtro;

  void _elegir(DateTime dia) {
    setState(() {
      _elegido = soloFecha(dia);
      _mes = DateTime(dia.year, dia.month);
    });
    widget.alCambiarDia?.call(_elegido);
  }

  void _cambiarMes(int delta) {
    setState(() => _mes = DateTime(_mes.year, _mes.month + delta));
  }

  void _irAHoy() => _elegir(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _estado,
      builder: (context, _) {
        final ahora = DateTime.now();
        final todas = _estado.citas.where(_pasaFiltro).toList();
        final delDia = todas.where((c) => mismoDia(c.fecha, _elegido)).toList();
        final proximas = todas
            .where((c) => !c.yaPaso(ahora) && !mismoDia(c.fecha, _elegido))
            .take(10)
            .toList();

        // Tipos de cita por día, para los puntitos del calendario.
        final marcas = <String, Set<TipoCita>>{};
        for (final c in todas) {
          marcas.putIfAbsent(claveFecha(c.fecha), () => <TipoCita>{}).add(c.tipo);
        }

        final cuantas = _estado.proximasCitas(ahora).length;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: EncabezadoPantalla(
                titulo: 'Agenda',
                subtitulo: cuantas == 0
                    ? 'Consultas y laboratorios'
                    : cuantas == 1
                        ? '1 cita próxima'
                        : '$cuantas citas próximas',
                icono: Icons.calendar_month_rounded,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
              sliver: SliverList.list(
                children: [
                  _Filtros(
                    elegido: _filtro,
                    alCambiar: (t) => setState(() => _filtro = t),
                  ),
                  const SizedBox(height: 14),
                  _Calendario(
                    mes: _mes,
                    elegido: _elegido,
                    hoy: soloFecha(ahora),
                    marcas: marcas,
                    alCambiarMes: _cambiarMes,
                    alElegir: _elegir,
                    alIrAHoy: _irAHoy,
                  ),
                  const SizedBox(height: 22),
                  TituloSeccion(
                    fechaRelativa(_elegido, ahora) == fechaLarga(_elegido)
                        ? fechaLarga(_elegido)
                        : '${fechaRelativa(_elegido, ahora)}, ${fechaCorta(_elegido)}',
                  ),
                  if (delDia.isEmpty)
                    Tarjeta(
                      color: Colors.white,
                      child: Row(
                        children: [
                          const Icon(Icons.event_available_rounded, color: Cafe.textoSuave, size: 28),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Sin citas este día',
                              style: TextStyle(fontSize: 17, color: Cafe.textoSuave),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => widget.alAgregar(_elegido),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Agregar'),
                          ),
                        ],
                      ),
                    )
                  else
                    for (final c in delDia)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TarjetaCita(
                          cita: c,
                          ahora: ahora,
                          alTocar: () => mostrarDetalleCita(context, c),
                        ),
                      ),
                  if (proximas.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const TituloSeccion('Próximas citas'),
                    for (final c in proximas)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TarjetaCita(
                          cita: c,
                          ahora: ahora,
                          alTocar: () => mostrarDetalleCita(context, c),
                        ),
                      ),
                  ],
                  if (_estado.citas.isEmpty) ...[
                    const SizedBox(height: 8),
                    const EstadoVacio(
                      icono: Icons.event_note_rounded,
                      titulo: 'Tu agenda está vacía',
                      mensaje: 'Agrega tus consultas con el doctor y tus estudios de '
                          'laboratorio. Te avisaré antes de cada una.',
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

class _Filtros extends StatelessWidget {
  const _Filtros({required this.elegido, required this.alCambiar});

  final TipoCita? elegido;
  final ValueChanged<TipoCita?> alCambiar;

  @override
  Widget build(BuildContext context) {
    Widget chip(String texto, TipoCita? valor, IconData icono) {
      final activo = elegido == valor;
      return ChoiceChip(
        avatar: Icon(icono, size: 20, color: activo ? Colors.white : Cafe.cafe),
        label: Text(texto),
        labelStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: activo ? Colors.white : Cafe.espresso,
        ),
        selected: activo,
        selectedColor: Cafe.cafe,
        backgroundColor: Colors.white,
        showCheckmark: false,
        side: const BorderSide(color: Cafe.borde),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        onSelected: (_) => alCambiar(valor),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip('Todas', null, Icons.event_note_rounded),
        for (final t in TipoCita.values) chip(t.plural, t, EstiloCita.icono(t)),
      ],
    );
  }
}

/// Calendario mensual sencillo (lunes primero).
class _Calendario extends StatelessWidget {
  const _Calendario({
    required this.mes,
    required this.elegido,
    required this.hoy,
    required this.marcas,
    required this.alCambiarMes,
    required this.alElegir,
    required this.alIrAHoy,
  });

  final DateTime mes;
  final DateTime elegido;
  final DateTime hoy;
  final Map<String, Set<TipoCita>> marcas;
  final ValueChanged<int> alCambiarMes;
  final ValueChanged<DateTime> alElegir;
  final VoidCallback alIrAHoy;

  @override
  Widget build(BuildContext context) {
    final primerDia = DateTime(mes.year, mes.month, 1);
    final huecos = primerDia.weekday - 1; // lunes = 0 huecos
    final diasDelMes = DateTime(mes.year, mes.month + 1, 0).day;
    final celdas = ((huecos + diasDelMes) / 7).ceil() * 7;
    final esMesActual = mes.year == hoy.year && mes.month == hoy.month;

    return Tarjeta(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 14),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Mes anterior',
                onPressed: () => alCambiarMes(-1),
                icon: const Icon(Icons.chevron_left_rounded, size: 30),
              ),
              Expanded(
                child: Text(
                  nombreMes(mes),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                tooltip: 'Mes siguiente',
                onPressed: () => alCambiarMes(1),
                icon: const Icon(Icons.chevron_right_rounded, size: 30),
              ),
            ],
          ),
          if (!esMesActual || !mismoDia(elegido, hoy))
            TextButton.icon(
              onPressed: alIrAHoy,
              icon: const Icon(Icons.today_rounded, size: 20),
              label: const Text('Ir a hoy'),
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (final letra in const ['L', 'M', 'M', 'J', 'V', 'S', 'D'])
                Expanded(
                  child: Text(
                    letra,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Cafe.textoSuave,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          for (var fila = 0; fila < celdas ~/ 7; fila++)
            Row(
              children: [
                for (var col = 0; col < 7; col++)
                  Expanded(
                    child: _celda(fila * 7 + col - huecos + 1, diasDelMes),
                  ),
              ],
            ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Leyenda(tipo: TipoCita.consulta),
              SizedBox(width: 18),
              _Leyenda(tipo: TipoCita.laboratorio),
            ],
          ),
        ],
      ),
    );
  }

  Widget _celda(int numero, int diasDelMes) {
    if (numero < 1 || numero > diasDelMes) return const SizedBox(height: 50);

    final dia = DateTime(mes.year, mes.month, numero);
    final esElegido = mismoDia(dia, elegido);
    final esHoy = mismoDia(dia, hoy);
    final tipos = marcas[claveFecha(dia)] ?? const <TipoCita>{};

    return SizedBox(
      height: 50,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => alElegir(dia),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: esElegido ? Cafe.cafe : Colors.transparent,
                shape: BoxShape.circle,
                border: esHoy && !esElegido
                    ? Border.all(color: Cafe.caramelo, width: 2)
                    : null,
              ),
              child: Text(
                '$numero',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: esElegido || esHoy ? FontWeight.w800 : FontWeight.w600,
                  color: esElegido ? Colors.white : Cafe.espresso,
                ),
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              height: 6,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final t in TipoCita.values)
                    if (tipos.contains(t))
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(
                          color: EstiloCita.color(t),
                          shape: BoxShape.circle,
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Leyenda extends StatelessWidget {
  const _Leyenda({required this.tipo});

  final TipoCita tipo;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: EstiloCita.color(tipo),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          tipo.nombre,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Cafe.textoSuave),
        ),
      ],
    );
  }
}
