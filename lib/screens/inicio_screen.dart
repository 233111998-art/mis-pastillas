import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/app_state.dart';
import '../theme.dart';
import 'editar_pastilla_screen.dart';
import 'historial_screen.dart';
import 'hoy_screen.dart';
import 'mis_pastillas_screen.dart';

/// Pantalla principal con las pestañas Hoy / Mis pastillas / Historial.
class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  /// true mientras la pantalla principal existe (lo usa el manejo de avisos).
  static bool get estaAbierta => _abiertas > 0;
  static int _abiertas = 0;

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  final _pestana = AppState.instance.pestana;

  @override
  void initState() {
    super.initState();
    InicioScreen._abiertas++;
  }

  @override
  void dispose() {
    InicioScreen._abiertas--;
    super.dispose();
  }

  void _agregar() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const EditarPastillaScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _pestana,
      builder: (context, indice, _) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: estiloBarraClara,
          child: Scaffold(
            body: IndexedStack(
              index: indice,
              children: [
                HoyScreen(alAgregar: _agregar),
                MisPastillasScreen(alAgregar: _agregar),
                const HistorialScreen(),
              ],
            ),
            floatingActionButton: indice == 2
                ? null
                : FloatingActionButton.extended(
                    onPressed: _agregar,
                    icon: const Icon(Icons.add_rounded, size: 28),
                    label: const Text('Agregar pastilla'),
                  ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: indice,
              onDestinationSelected: (i) => _pestana.value = i,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.today_outlined),
                  selectedIcon: Icon(Icons.today_rounded),
                  label: 'Hoy',
                ),
                NavigationDestination(
                  icon: Icon(Icons.medication_outlined),
                  selectedIcon: Icon(Icons.medication_rounded),
                  label: 'Mis pastillas',
                ),
                NavigationDestination(
                  icon: Icon(Icons.history_rounded),
                  selectedIcon: Icon(Icons.history_rounded),
                  label: 'Historial',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
