import 'package:flutter/material.dart';

import '../app.dart';
import '../config.dart';
import '../data/app_state.dart';
import '../models/cita.dart';
import '../theme.dart';
import '../utils/fechas.dart';
import '../widgets/cita_widgets.dart';
import '../widgets/comunes.dart';
import '../widgets/selector_hora.dart';

/// Formulario para agregar o editar una consulta o un laboratorio.
class EditarCitaScreen extends StatefulWidget {
  const EditarCitaScreen({super.key, this.cita, this.diaInicial});

  /// null = cita nueva.
  final Cita? cita;

  /// Día sugerido para una cita nueva (el que está elegido en el calendario).
  final DateTime? diaInicial;

  @override
  State<EditarCitaScreen> createState() => _EditarCitaScreenState();
}

class _EditarCitaScreenState extends State<EditarCitaScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titulo;
  late final TextEditingController _lugar;
  late final TextEditingController _notas;

  late TipoCita _tipo;
  late DateTime _dia;
  late int _minutos;
  late bool _ayunas;
  late bool _avisoDiaAntes;
  late int _avisoHorasAntes;
  bool _guardando = false;

  bool get _esNueva => widget.cita == null;

  static const _opcionesHoras = [0, 1, 2, 3];

  @override
  void initState() {
    super.initState();
    final c = widget.cita;
    final hoy = soloFecha(DateTime.now());
    final sugerido = widget.diaInicial == null || soloFecha(widget.diaInicial!).isBefore(hoy)
        ? hoy
        : soloFecha(widget.diaInicial!);

    _titulo = TextEditingController(text: c?.titulo ?? '');
    _lugar = TextEditingController(text: c?.lugar ?? '');
    _notas = TextEditingController(text: c?.notas ?? '');
    _tipo = c?.tipo ?? TipoCita.consulta;
    _dia = c == null ? sugerido : soloFecha(c.fecha);
    _minutos = c?.minutos ?? 9 * 60;
    _ayunas = c?.ayunas ?? false;
    _avisoDiaAntes = c?.avisoDiaAntes ?? true;
    _avisoHorasAntes = c?.avisoHorasAntes ?? 2;
  }

  @override
  void dispose() {
    _titulo.dispose();
    _lugar.dispose();
    _notas.dispose();
    super.dispose();
  }

  DateTime get _fecha => DateTime(
        _dia.year,
        _dia.month,
        _dia.day,
        _minutos ~/ 60,
        _minutos % 60,
      );

  Future<void> _elegirDia() async {
    final hoy = soloFecha(DateTime.now());
    final primero = _dia.isBefore(hoy) ? _dia : hoy;
    final elegida = await showDatePicker(
      context: context,
      initialDate: _dia,
      firstDate: sumarDias(primero, -365),
      lastDate: sumarDias(hoy, 3 * 365),
      helpText: '¿Qué día es la cita?',
      cancelText: 'Cancelar',
      confirmText: 'Listo',
    );
    if (elegida != null && mounted) setState(() => _dia = soloFecha(elegida));
  }

  Future<void> _elegirHora() async {
    final minutos = await elegirHora(context, inicial: _minutos);
    if (minutos != null && mounted) setState(() => _minutos = minutos);
  }

  Future<void> _guardar() async {
    if (_guardando) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _guardando = true);
    final cita = Cita(
      id: widget.cita?.id ?? AppState.instance.nuevoId(),
      tipo: _tipo,
      titulo: _titulo.text.trim(),
      fecha: _fecha,
      lugar: _lugar.text.trim(),
      notas: _notas.text.trim(),
      ayunas: _tipo == TipoCita.laboratorio && _ayunas,
      avisoDiaAntes: _avisoDiaAntes,
      avisoHorasAntes: _avisoHorasAntes,
    );
    await AppState.instance.guardarCita(cita);
    if (!mounted) return;

    Navigator.of(context).pop();
    final ahora = DateTime.now();
    mostrarMensaje(
      cita.yaPaso(ahora)
          ? 'Cita guardada en tu agenda.'
          : 'Listo: ${cita.titulo}, ${cita.cuando(ahora).toLowerCase()}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final esLab = _tipo == TipoCita.laboratorio;
    final ahora = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Cafe.crema,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _esNueva ? 'Nueva cita' : 'Editar cita',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const _Pregunta('¿Qué es?'),
            SegmentedButton<TipoCita>(
              showSelectedIcon: false,
              segments: [
                for (final t in TipoCita.values)
                  ButtonSegment(
                    value: t,
                    icon: Icon(EstiloCita.icono(t)),
                    label: Text(t.nombre),
                  ),
              ],
              selected: {_tipo},
              onSelectionChanged: (s) => setState(() => _tipo = s.first),
            ),

            _Pregunta(esLab ? '¿Qué estudio?' : '¿Con quién?'),
            TextFormField(
              controller: _titulo,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: esLab ? 'Ej. Química sanguínea' : 'Ej. Cardiólogo, Dr. Pérez',
                prefixIcon: Icon(EstiloCita.icono(_tipo)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? (esLab ? 'Escribe qué estudio es' : 'Escribe con quién es la consulta')
                  : null,
            ),

            const _Pregunta('¿Cuándo?'),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _BotonDato(
                    icono: Icons.event_rounded,
                    etiqueta: fechaRelativa(_dia, ahora),
                    valor: fechaCorta(_dia),
                    alTocar: _elegirDia,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _BotonDato(
                    icono: Icons.schedule_rounded,
                    etiqueta: 'Hora',
                    valor: formatoHora(_minutos),
                    alTocar: _elegirHora,
                  ),
                ),
              ],
            ),
            if (_fecha.isBefore(ahora)) ...[
              const SizedBox(height: 8),
              const Text(
                'Esta fecha ya pasó. Se guardará en tu agenda sin avisos.',
                style: TextStyle(fontSize: 15, color: Cafe.ambar, fontWeight: FontWeight.w700),
              ),
            ],

            const _Pregunta('¿Dónde? (opcional)'),
            TextFormField(
              controller: _lugar,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              style: const TextStyle(fontSize: 18),
              decoration: const InputDecoration(
                hintText: 'Ej. Clínica 23, consultorio 5',
                prefixIcon: Icon(Icons.place_rounded),
              ),
            ),

            if (esLab) ...[
              const SizedBox(height: 14),
              Tarjeta(
                color: _ayunas ? Cafe.ambarClaro : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: SwitchListTile(
                  value: _ayunas,
                  onChanged: (v) => setState(() => _ayunas = v),
                  activeThumbColor: Cafe.ambar,
                  secondary: const Icon(Icons.no_food_rounded, color: Cafe.ambar, size: 28),
                  title: const Text(
                    'Ir en ayunas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  subtitle: const Text(
                    'Te lo recordaré la noche anterior.',
                    style: TextStyle(fontSize: 15),
                  ),
                ),
              ),
            ],

            const _Pregunta('Avisos'),
            Tarjeta(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: SwitchListTile(
                value: _avisoDiaAntes,
                onChanged: (v) => setState(() => _avisoDiaAntes = v),
                activeThumbColor: Cafe.cafe,
                secondary: const Icon(Icons.nightlight_round, color: Cafe.cafe, size: 28),
                title: const Text(
                  'Un día antes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  'A las ${formatoHora(kHoraAvisoDiaAntes)} del día anterior',
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'El mismo día, ¿cuánto antes te aviso?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Cafe.textoSuave),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final h in _opcionesHoras)
                  ChoiceChip(
                    label: Text(h == 0 ? 'No avisar' : (h == 1 ? '1 hora' : '$h horas')),
                    labelStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _avisoHorasAntes == h ? Colors.white : Cafe.espresso,
                    ),
                    selected: _avisoHorasAntes == h,
                    selectedColor: Cafe.cafe,
                    backgroundColor: Colors.white,
                    showCheckmark: false,
                    side: const BorderSide(color: Cafe.borde),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    onSelected: (_) => setState(() => _avisoHorasAntes = h),
                  ),
              ],
            ),

            const _Pregunta('Notas (opcional)'),
            TextFormField(
              controller: _notas,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              style: const TextStyle(fontSize: 18),
              decoration: InputDecoration(
                hintText: esLab
                    ? 'Ej. Llevar la orden del doctor'
                    : 'Ej. Llevar mis estudios y la lista de pastillas',
                prefixIcon: const Icon(Icons.sticky_note_2_rounded),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(62)),
            onPressed: _guardando ? null : _guardar,
            icon: _guardando
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : const Icon(Icons.check_rounded, size: 26),
            label: Text(
              _esNueva ? 'Guardar cita' : 'Guardar cambios',
              style: const TextStyle(fontSize: 19),
            ),
          ),
        ),
      ),
    );
  }
}

class _Pregunta extends StatelessWidget {
  const _Pregunta(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 26, bottom: 12),
      child: Text(texto, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}

/// Botón grande que muestra un dato (fecha u hora) y se toca para cambiarlo.
class _BotonDato extends StatelessWidget {
  const _BotonDato({
    required this.icono,
    required this.etiqueta,
    required this.valor,
    required this.alTocar,
  });

  final IconData icono;
  final String etiqueta;
  final String valor;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    return Tarjeta(
      color: Colors.white,
      onTap: alTocar,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icono, color: Cafe.cafe, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etiqueta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, color: Cafe.textoSuave),
                ),
                Text(
                  valor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
