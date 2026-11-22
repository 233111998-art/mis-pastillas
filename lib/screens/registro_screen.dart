import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../data/app_state.dart';
import '../services/notificaciones.dart';
import '../theme.dart';

/// Pide el nombre de quien usa la app (cada familiar en su celular).
/// Se muestra la primera vez y también desde Ajustes para cambiarlo.
class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key, this.primeraVez = false});

  /// true = primera vez (al terminar entra a la app);
  /// false = cambiar nombre desde Ajustes (al terminar regresa).
  final bool primeraVez;

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late bool _masculino;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final estado = AppState.instance;
    _nombre = TextEditingController(text: estado.nombre);
    _masculino = estado.masculino;
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _continuar() async {
    if (_guardando) return;
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _guardando = true);
    await AppState.instance.guardarPerfil(_nombre.text, masculino: _masculino);

    if (widget.primeraVez) {
      // La primera vez Android/iPhone preguntan si la app puede mandar avisos.
      try {
        await Notificaciones.instance.pedirPermisos();
      } catch (_) {}
      if (!mounted) return;
      Navigator.of(context).pushReplacement(crearRutaInicio());
    } else {
      if (!mounted) return;
      Navigator.of(context).pop();
      mostrarMensaje('Listo, ${AppState.instance.nombre}.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: estiloBarraClara,
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(gradient: Cafe.degradado),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, limites) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: math.max(0.0, limites.maxHeight - 44),
                  ),
                  child: IntrinsicHeight(child: _contenido(context)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _contenido(BuildContext context) {
    final nombre = _nombre.text.trim();
    final vistaPrevia = nombre.isEmpty
        ? '¡${_masculino ? 'Bienvenido' : 'Bienvenida'}!'
        : '¡${_masculino ? 'Bienvenido' : 'Bienvenida'}, $nombre!';

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.primeraVez)
            IconButton(
              tooltip: 'Regresar',
              onPressed: () => Navigator.of(context).pop(),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.14),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          const Spacer(),
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: Cafe.crema,
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(Icons.waving_hand_rounded, size: 46, color: Cafe.caramelo),
          ),
          const SizedBox(height: 28),
          Text(
            widget.primeraVez ? '¡Hola!' : 'Tu nombre',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Cafe.latte.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '¿Cómo te llamas?',
            style: TextStyle(
              fontSize: 38,
              height: 1.1,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Así te saludaremos y aparecerá en tus avisos.',
            style: TextStyle(fontSize: 17, color: Colors.white.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 22),
          TextFormField(
            controller: _nombre,
            autofocus: widget.primeraVez,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onFieldSubmitted: (_) => _continuar(),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            decoration: const InputDecoration(
              hintText: 'Escribe tu nombre',
              prefixIcon: Icon(Icons.person_rounded),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Escribe tu nombre para continuar' : null,
          ),
          const SizedBox(height: 22),
          Text(
            '¿Cómo te damos la bienvenida?',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _OpcionSaludo(
                  texto: 'Bienvenida',
                  elegida: !_masculino,
                  alTocar: () => setState(() => _masculino = false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _OpcionSaludo(
                  texto: 'Bienvenido',
                  elegida: _masculino,
                  alTocar: () => setState(() => _masculino = true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              vistaPrevia,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w700,
                color: Cafe.latte.withValues(alpha: 0.95),
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Cafe.crema,
                foregroundColor: Cafe.espresso,
                minimumSize: const Size.fromHeight(64),
              ),
              onPressed: _guardando ? null : _continuar,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.primeraVez ? 'Continuar' : 'Guardar',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward_rounded, size: 26),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpcionSaludo extends StatelessWidget {
  const _OpcionSaludo({
    required this.texto,
    required this.elegida,
    required this.alTocar,
  });

  final String texto;
  final bool elegida;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: elegida ? Cafe.crema : Colors.white.withValues(alpha: 0.10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: elegida ? Cafe.crema : Colors.white.withValues(alpha: 0.25),
          width: 1.4,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: alTocar,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                elegida ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: elegida ? Cafe.cafe : Colors.white70,
                size: 22,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  texto,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: elegida ? Cafe.espresso : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
