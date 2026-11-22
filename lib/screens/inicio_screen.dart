import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/app_state.dart';
import '../theme.dart';
import 'agenda_screen.dart';
import 'editar_cita_screen.dart';
import 'editar_pastilla_screen.dart';
import 'historial_screen.dart';
import 'hoy_screen.dart';
import 'mis_pastillas_screen.dart';

/// Pantalla principal con las pestañas Hoy / Pastillas / Agenda / Historial.
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

  /// Día elegido en el calendario de la Agenda (para sugerirlo en citas nuevas).
  DateTime? _diaAgenda;

  void _agregarCita([DateTime? dia]) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EditarCitaScreen(diaInicial: dia ?? _diaAgenda),
      ),
    );
  }

  Widget? _botonFlotante(int indice) {
    switch (indice) {
      case AppState.pestanaHoy:
      case AppState.pestanaPastillas:
        return FloatingActionButton.extended(
          onPressed: _agregar,
          icon: const Icon(Icons.add_rounded, size: 28),
          label: const Text('Agregar pastilla'),
        );
      case AppState.pestanaAgenda:
        return FloatingActionButton.extended(
          onPressed: _agregarCita,
          icon: const Icon(Icons.add_rounded, size: 28),
          label: const Text('Agregar cita'),
        );
      default:
        return null;
    }
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
                AgendaScreen(
                  alAgregar: _agregarCita,
                  alCambiarDia: (dia) => _diaAgenda = dia,
                ),
                const HistorialScreen(),
              ],
            ),
            floatingActionButton: _botonFlotante(indice),
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
                  label: 'Pastillas',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month_rounded),
                  label: 'Agenda',
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
