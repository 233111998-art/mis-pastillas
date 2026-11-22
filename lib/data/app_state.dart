import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/medicina.dart';
import '../services/notificaciones.dart';
import '../utils/fechas.dart';

/// Guarda las pastillas y el registro de tomas, y avisa a las pantallas
/// cuando algo cambia.
class AppState extends ChangeNotifier {
  AppState._();
  static final AppState instance = AppState._();

  static const _kMedicinas = 'medicinas_v1';
  static const _kTomas = 'tomas_v1';

  /// Cuántos días de historial se guardan.
  static const diasDeHistorial = 60;

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  List<Medicina> _medicinas = [];
  Map<String, DateTime> _tomas = {};

  /// Pestaña visible en la pantalla principal (0 = Hoy).
  final ValueNotifier<int> pestana = ValueNotifier<int>(0);

  List<Medicina> get medicinas => List.unmodifiable(_medicinas);

  // ---------------------------------------------------------------------------
  // Carga y guardado
  // ---------------------------------------------------------------------------

  Future<void> cargar() async {
    try {
      final raw = await _prefs.getString(_kMedicinas);
      if (raw != null) {
        final lista = jsonDecode(raw) as List<dynamic>;
        _medicinas = lista
            .map((e) => Medicina.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('No se pudieron leer las pastillas: $e');
    }

    try {
      final raw = await _prefs.getString(_kTomas);
      if (raw != null) {
        final mapa = jsonDecode(raw) as Map<String, dynamic>;
        _tomas = mapa.map((k, v) => MapEntry(k, DateTime.parse(v as String)));
      }
    } catch (e) {
      debugPrint('No se pudo leer el registro de tomas: $e');
    }

    _limpiarTomasViejas();
    notifyListeners();
  }

  Future<void> _guardarMedicinas() => _prefs.setString(
        _kMedicinas,
        jsonEncode(_medicinas.map((m) => m.toJson()).toList()),
      );

  Future<void> _guardarTomas() => _prefs.setString(
        _kTomas,
        jsonEncode(_tomas.map((k, v) => MapEntry(k, v.toIso8601String()))),
      );

  void _limpiarTomasViejas() {
    final limite = claveFecha(sumarDias(DateTime.now(), -diasDeHistorial));
    _tomas.removeWhere((clave, _) {
      final partes = clave.split('|');
      // Las claves de fecha "aaaa-mm-dd" se pueden comparar como texto.
      return partes.length != 3 || partes[1].compareTo(limite) < 0;
    });
  }

  /// Para que las pantallas recalculen estados (por ejemplo al volver a la app).
  void refrescar() => notifyListeners();

  // ---------------------------------------------------------------------------
  // Pastillas
  // ---------------------------------------------------------------------------

  Medicina? buscar(String id) {
    for (final m in _medicinas) {
      if (m.id == id) return m;
    }
    return null;
  }

  String nuevoId() => DateTime.now().microsecondsSinceEpoch.toString();

  Future<void> guardarMedicina(Medicina medicina) async {
    final i = _medicinas.indexWhere((m) => m.id == medicina.id);
    if (i >= 0) {
      _medicinas[i] = medicina;
    } else {
      _medicinas.add(medicina);
    }
    notifyListeners();
    await _guardarMedicinas();
    await reprogramarAvisos();
  }

  Future<void> eliminarMedicina(String id) async {
    _medicinas.removeWhere((m) => m.id == id);
    _tomas.removeWhere((clave, _) => clave.startsWith('$id|'));
    notifyListeners();
    await _guardarMedicinas();
    await _guardarTomas();
    await reprogramarAvisos();
  }

  Future<void> _cola = Future<void>.value();

  /// Vuelve a programar todos los avisos. Las llamadas se hacen en fila
  /// para que dos reprogramaciones nunca se mezclen.
  Future<void> reprogramarAvisos() {
    final siguiente = _cola.then((_) async {
      try {
        await Notificaciones.instance.reprogramar(List.of(_medicinas));
      } catch (e) {
        debugPrint('No se pudieron programar los avisos: $e');
      }
    });
    _cola = siguiente;
    return siguiente;
  }

  // ---------------------------------------------------------------------------
  // Tomas
  // ---------------------------------------------------------------------------

  DateTime? tomadaA(String medId, DateTime dia, int minutos) =>
      _tomas[claveToma(medId, dia, minutos)];

  Future<void> marcarTomada(String medId, DateTime dia, int minutos) async {
    final clave = claveToma(medId, dia, minutos);
    if (_tomas.containsKey(clave)) return; // ya estaba registrada
    _tomas[clave] = DateTime.now();
    notifyListeners();
    await _guardarTomas();
  }

  Future<void> desmarcar(String medId, DateTime dia, int minutos) async {
    _tomas.remove(claveToma(medId, dia, minutos));
    notifyListeners();
    await _guardarTomas();
  }

  /// Todas las tomas de un día, ordenadas por hora.
  List<Dosis> dosisDelDia(DateTime dia) {
    final d = soloFecha(dia);
    final lista = <Dosis>[];
    for (final m in _medicinas) {
      if (!m.activaEn(d)) continue;
      for (final minutos in m.horarios) {
        lista.add(Dosis(
          medicina: m,
          dia: d,
          minutos: minutos,
          tomadaA: tomadaA(m.id, d, minutos),
        ));
      }
    }
    lista.sort((a, b) {
      final porHora = a.minutos.compareTo(b.minutos);
      return porHora != 0
          ? porHora
          : a.medicina.nombre.toLowerCase().compareTo(b.medicina.nombre.toLowerCase());
    });
    return lista;
  }
}
