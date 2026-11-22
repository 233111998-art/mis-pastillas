import 'package:flutter/material.dart';

import '../theme.dart';

/// Círculo de color con el icono de pastilla.
class IconoPastilla extends StatelessWidget {
  const IconoPastilla({
    super.key,
    required this.color,
    this.tamano = 52,
    this.apagado = false,
  });

  final Color color;
  final double tamano;
  final bool apagado;

  @override
  Widget build(BuildContext context) {
    final base = apagado ? Cafe.textoSuave : color;
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        color: base.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(tamano * 0.34),
      ),
      child: Icon(Icons.medication_rounded, color: base, size: tamano * 0.56),
    );
  }
}

/// Etiqueta redondeada con icono y texto.
class Etiqueta extends StatelessWidget {
  const Etiqueta({
    super.key,
    required this.texto,
    required this.color,
    required this.fondo,
    this.icono,
  });

  final String texto;
  final Color color;
  final Color fondo;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[
            Icon(icono, size: 18, color: color),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              texto,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Título de sección.
class TituloSeccion extends StatelessWidget {
  const TituloSeccion(this.texto, {super.key, this.detalle});

  final String texto;
  final String? detalle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(texto, style: Theme.of(context).textTheme.titleLarge),
          ),
          if (detalle != null)
            Text(
              detalle!,
              style: const TextStyle(
                color: Cafe.textoSuave,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

/// Tarjeta clara con bordes redondeados.
class Tarjeta extends StatelessWidget {
  const Tarjeta({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(18),
    this.color = Cafe.espuma,
    this.borde,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color? borde;

  @override
  Widget build(BuildContext context) {
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: BorderSide(color: borde ?? Cafe.borde, width: 1.2),
    );
    return Material(
      color: color,
      shape: forma,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Mensaje grande para cuando una lista está vacía.
class EstadoVacio extends StatelessWidget {
  const EstadoVacio({
    super.key,
    required this.icono,
    required this.titulo,
    required this.mensaje,
    this.accion,
  });

  final IconData icono;
  final String titulo;
  final String mensaje;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: Cafe.latte,
              shape: BoxShape.circle,
            ),
            child: Icon(icono, size: 48, color: Cafe.cafe),
          ),
          const SizedBox(height: 20),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, color: Cafe.textoSuave),
          ),
          if (accion != null) ...[
            const SizedBox(height: 24),
            accion!,
          ],
        ],
      ),
    );
  }
}
