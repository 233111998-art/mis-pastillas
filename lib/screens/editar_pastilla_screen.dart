import 'package:flutter/material.dart';

import '../app.dart';
import '../config.dart';
import '../data/app_state.dart';
import '../models/medicina.dart';
import '../theme.dart';
import '../utils/fechas.dart';
import '../widgets/comunes.dart';
import '../widgets/selector_hora.dart';

/// Formulario para agregar o editar una pastilla.
class EditarPastillaScreen extends StatefulWidget {
  const EditarPastillaScreen({super.key, this.medicina});

  /// null = pastilla nueva.
  final Medicina? medicina;

  @override
  State<EditarPastillaScreen> createState() => _EditarPastillaScreenState();
}

class _EditarPastillaScreenState extends State<EditarPastillaScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _dosis;
  late final TextEditingController _notas;

  late TipoTratamiento _tipo;
  late int _dias;
  late DateTime _inicio;
  late List<int> _horarios;
  late int _color;
  bool _guardando = false;

  bool get _esNueva => widget.medicina == null;

  static const _diasRapidos = [3, 5, 7, 10, 14, 30];

  @override
  void initState() {
    super.initState();
    final m = widget.medicina;
    _nombre = TextEditingController(text: m?.nombre ?? '');
    _dosis = TextEditingController(text: m?.dosis ?? '');
    _notas = TextEditingController(text: m?.notas ?? '');
    _tipo = m?.tipo ?? TipoTratamiento.permanente;
    _dias = m?.dias ?? 7;
    _inicio = m?.fechaInicio ?? soloFecha(DateTime.now());
    _horarios = [...?m?.horarios];
    if (_horarios.isEmpty) _horarios = [8 * 60];
    _color = m?.color ?? (AppState.instance.medicinas.length % Cafe.pastillas.length);
  }

  @override
  void dispose() {
    _nombre.dispose();
    _dosis.dispose();
    _notas.dispose();
    super.dispose();
  }

  Future<void> _agregarHora() async {
    final sugerida = _horarios.isEmpty ? 8 * 60 : (_horarios.last + 12 * 60) % (24 * 60);
    final minutos = await elegirHora(context, inicial: sugerida);
    if (minutos == null || !mounted) return;
    if (_horarios.contains(minutos)) {
      mostrarMensaje('Esa hora ya está en la lista.');
      return;
    }
    setState(() => _horarios = [..._horarios, minutos]..sort());
  }

  Future<void> _cambiarHora(int actual) async {
    final minutos = await elegirHora(context, inicial: actual);
    if (minutos == null || !mounted || minutos == actual) return;
    if (_horarios.contains(minutos)) {
      mostrarMensaje('Esa hora ya está en la lista.');
      return;
    }
    setState(() {
      _horarios = [..._horarios.where((h) => h != actual), minutos]..sort();
    });
  }

  void _quitarHora(int minutos) {
    if (_horarios.length == 1) {
      mostrarMensaje('Debe quedar al menos una hora.');
      return;
    }
    setState(() => _horarios = _horarios.where((h) => h != minutos).toList());
  }

  Future<void> _elegirInicio() async {
    final hoy = soloFecha(DateTime.now());
    final elegida = await showDatePicker(
      context: context,
      initialDate: _inicio,
      firstDate: sumarDias(hoy, -30),
      lastDate: sumarDias(hoy, 365),
      helpText: '¿Qué día empiezas?',
      cancelText: 'Cancelar',
      confirmText: 'Listo',
    );
    if (elegida != null && mounted) setState(() => _inicio = soloFecha(elegida));
  }

  void _cambiarDias(int valor) {
    setState(() => _dias = valor.clamp(1, kMaxDiasTemporal).toInt());
  }

  Future<void> _guardar() async {
    if (_guardando) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_horarios.isEmpty) {
      mostrarMensaje('Agrega al menos una hora.');
      return;
    }

    setState(() => _guardando = true);

    final hoy = soloFecha(DateTime.now());
    final base = widget.medicina;
    final DateTime inicio;
    if (_tipo == TipoTratamiento.permanente) {
      // Conserva la fecha original para que el historial siga completo.
      inicio = (base != null && base.fechaInicio.isBefore(hoy)) ? base.fechaInicio : hoy;
    } else {
      inicio = _inicio;
    }

    final medicina = Medicina(
      id: base?.id ?? AppState.instance.nuevoId(),
      nombre: _nombre.text.trim(),
      dosis: _dosis.text.trim(),
      notas: _notas.text.trim(),
      tipo: _tipo,
      horarios: _horarios,
      fechaInicio: inicio,
      dias: _dias,
      color: _color,
    );

    await AppState.instance.guardarMedicina(medicina);
    if (!mounted) return;

    Navigator.of(context).pop();
    final horas = medicina.horarios.map(formatoHora).toList();
    final lista = horas.length == 1
        ? horas.first
        : '${horas.sublist(0, horas.length - 1).join(', ')} y ${horas.last}';
    mostrarMensaje('Listo. Te avisaré a las $lista.');
  }

  @override
  Widget build(BuildContext context) {
    final fin = sumarDias(_inicio, _dias - 1);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Cafe.crema,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _esNueva ? 'Nueva pastilla' : 'Editar pastilla',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const _Pregunta('¿Cómo se llama?'),
            TextFormField(
              controller: _nombre,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(
                labelText: 'Nombre de la pastilla',
                hintText: 'Ej. Losartán',
                prefixIcon: Icon(Icons.medication_rounded),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Escribe el nombre de la pastilla' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dosis,
              textInputAction: TextInputAction.next,
              style: const TextStyle(fontSize: 18),
              decoration: const InputDecoration(
                labelText: 'Dosis (opcional)',
                hintText: 'Ej. 50 mg o 1 tableta',
                prefixIcon: Icon(Icons.scale_rounded),
              ),
            ),

            const _Pregunta('¿Por cuánto tiempo?'),
            SegmentedButton<TipoTratamiento>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: TipoTratamiento.permanente,
                  icon: Icon(Icons.all_inclusive_rounded),
                  label: Text('Para siempre'),
                ),
                ButtonSegment(
                  value: TipoTratamiento.temporal,
                  icon: Icon(Icons.date_range_rounded),
                  label: Text('Unos días'),
                ),
              ],
              selected: {_tipo},
              onSelectionChanged: (s) => setState(() => _tipo = s.first),
            ),
            const SizedBox(height: 10),
            Text(
              _tipo == TipoTratamiento.permanente
                  ? 'Para las de todos los días, como la de la presión.'
                  : 'Para tratamientos cortos, como un antibiótico.',
              style: const TextStyle(fontSize: 16, color: Cafe.textoSuave),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              child: _tipo == TipoTratamiento.temporal
                  ? Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: _tarjetaDias(fin),
                    )
                  : const SizedBox(width: double.infinity),
            ),

            const _Pregunta('¿A qué hora te la tomas?'),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final h in _horarios)
                  _ChipHora(
                    texto: formatoHora(h),
                    alTocar: () => _cambiarHora(h),
                    alQuitar: () => _quitarHora(h),
                  ),
                _BotonAgregarHora(alTocar: _agregarHora),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Toca una hora para cambiarla.',
              style: TextStyle(fontSize: 15, color: Cafe.textoSuave),
            ),

            const _Pregunta('Color para reconocerla'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (var i = 0; i < Cafe.pastillas.length; i++)
                  _CirculoColor(
                    color: Cafe.pastillas[i],
                    elegido: i == _color,
                    alTocar: () => setState(() => _color = i),
                  ),
              ],
            ),

            const _Pregunta('Notas (opcional)'),
            TextFormField(
              controller: _notas,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              style: const TextStyle(fontSize: 18),
              decoration: const InputDecoration(
                hintText: 'Ej. Con el desayuno',
                prefixIcon: Icon(Icons.sticky_note_2_rounded),
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
              _esNueva ? 'Guardar pastilla' : 'Guardar cambios',
              style: const TextStyle(fontSize: 19),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tarjetaDias(DateTime fin) {
    return Tarjeta(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Días de tratamiento',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              BotonRedondo(
                icono: Icons.remove_rounded,
                alPresionar: _dias > 1 ? () => _cambiarDias(_dias - 1) : null,
              ),
              SizedBox(
                width: 52,
                child: Text(
                  '$_dias',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                ),
              ),
              BotonRedondo(
                icono: Icons.add_rounded,
                alPresionar: _dias < kMaxDiasTemporal ? () => _cambiarDias(_dias + 1) : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final n in _diasRapidos)
                ChoiceChip(
                  label: Text('$n días'),
                  labelStyle: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _dias == n ? Colors.white : Cafe.espresso,
                  ),
                  selected: _dias == n,
                  selectedColor: Cafe.cafe,
                  backgroundColor: Cafe.crema,
                  showCheckmark: false,
                  side: const BorderSide(color: Cafe.borde),
                  onSelected: (_) => _cambiarDias(n),
                ),
            ],
          ),
          const Divider(height: 28),
          Row(
            children: [
              const Icon(Icons.event_rounded, color: Cafe.cafe),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Empieza',
                      style: TextStyle(fontSize: 14, color: Cafe.textoSuave),
                    ),
                    Text(
                      fechaRelativa(_inicio, DateTime.now()) == 'Hoy'
                          ? 'Hoy, ${fechaCorta(_inicio)}'
                          : fechaLarga(_inicio),
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              TextButton(onPressed: _elegirInicio, child: const Text('Cambiar')),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Cafe.crema,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.flag_rounded, color: Cafe.caramelo),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Última toma: ${fechaLarga(fin)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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

class _ChipHora extends StatelessWidget {
  const _ChipHora({
    required this.texto,
    required this.alTocar,
    required this.alQuitar,
  });

  final String texto;
  final VoidCallback alTocar;
  final VoidCallback alQuitar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Cafe.latte,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: alTocar,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 4, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.schedule_rounded, color: Cafe.cafe, size: 22),
              const SizedBox(width: 8),
              Text(
                texto,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              IconButton(
                tooltip: 'Quitar hora',
                onPressed: alQuitar,
                icon: const Icon(Icons.close_rounded, size: 20, color: Cafe.textoSuave),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BotonAgregarHora extends StatelessWidget {
  const _BotonAgregarHora({required this.alTocar});

  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Cafe.cafe, width: 1.4),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: alTocar,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: Cafe.cafe),
              SizedBox(width: 6),
              Text(
                'Agregar hora',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Cafe.cafe),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CirculoColor extends StatelessWidget {
  const _CirculoColor({
    required this.color,
    required this.elegido,
    required this.alTocar,
  });

  final Color color;
  final bool elegido;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: elegido,
      label: 'Color',
      child: GestureDetector(
        onTap: alTocar,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: elegido ? Cafe.espresso : Colors.white,
              width: elegido ? 3.5 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: elegido ? 12 : 4,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: elegido ? const Icon(Icons.check_rounded, color: Colors.white, size: 28) : null,
        ),
      ),
    );
  }
}
