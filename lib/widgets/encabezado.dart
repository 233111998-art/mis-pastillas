import 'package:flutter/material.dart';

import '../theme.dart';

/// Encabezado café con título grande (para las pestañas).
class EncabezadoPantalla extends StatelessWidget {
  const EncabezadoPantalla({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.icono,
  });

  final String titulo;
  final String subtitulo;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    final arriba = MediaQuery.paddingOf(context).top;
    return Container(
      padding: EdgeInsets.fromLTRB(24, arriba + 20, 24, 26),
      decoration: const BoxDecoration(
        gradient: Cafe.degradado,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitulo,
                  style: TextStyle(
                    fontSize: 17,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icono, color: Cafe.latte, size: 30),
          ),
        ],
      ),
    );
  }
}
