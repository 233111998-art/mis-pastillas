import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cita.dart';
import '../models/medicina.dart';
import '../services/notificaciones.dart';
import '../utils/fechas.dart';

/// Guarda el perfil, las pastillas, las tomas y las citas, y avisa a las
/// pantallas cuando algo cambia.
class AppState extends ChangeNotifier {
  AppState._();
  static final AppState instance = AppState._();

  static const _kMedicinas = 'medicinas_v1';
  static const _kTomas = 'tomas_v1';
  static const _kCitas = 'citas_v1';
  static const _kNombre = 'perfil_nombre';
  static const _kMasculino = 'perfil_masculino';

  /// Cuántos días de historial se guardan.
  static const diasDeHistorial = 60;

  /// Pestañas de la pantalla principal.
  static const pestanaHoy = 0;
  static const pestanaPastillas = 1;
  static const pestanaAgenda = 2;
  static const pestanaHistorial = 3;

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  String _nombre = '';
  bool _masculino = false;
  List<Medicina> _medicinas = [];
  Map<String, DateTime> _tomas = {};
  List<Cita> _citas = [];

  /// Pestaña visible en la pantalla principal.
  final ValueNotifier<int> pestana = ValueNotifier<int>(pestanaHoy);

  /// Cita que la Agenda debe mostrar (por ejemplo, al tocar su aviso).
  final ValueNotifier<String?> citaEnfocada = ValueNotifier<String?>(null);

  List<Medicina> get medicinas => List.unmodifiable(_medicinas);
  List<Cita> get citas => List.unmodifiable(_citas);

  // ---------------------------------------------------------------------------
  // Perfil
  // ---------------------------------------------------------------------------

  String get nombre => _nombre;
  bool get masculino => _masculino;
  bool get tienePerfil => _nombre.trim().isNotEmpty;

  /// "Bienvenida" o "Bienvenido".
  String get palabraBienvenida => _masculino ? 'Bienvenido' : 'Bienvenida';

  Future<void> guardarPerfil(String nombre, {required bool masculino}) async {
    _nombre = nombre.trim();
    _masculino = masculino;
    notifyListeners();
    await _prefs.setString(_kNombre, _nombre);
    await _prefs.setBool(_kMasculino, _masculino);
    // El nombre aparece en el título de los avisos.
    await reprogramarAvisos();
  }

  // ---------------------------------------------------------------------------
  // Carga y guardado
  // ---------------------------------------------------------------------------

  Future<void> cargar() async {
    try {
      _nombre = (await _prefs.getString(_kNombre)) ?? '';
      _masculino = (await _prefs.getBool(_kMasculino)) ?? false;
    } catch (e) {
      debugPrint('No se pudo leer el perfil: $e');
    }

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

    try {
      final raw = await _prefs.getString(_kCitas);
      if (raw != null) {
        final lista = jsonDecode(raw) as List<dynamic>;
        _citas = lista.map((e) => Cita.fromJson(e as Map<String, dynamic>)).toList();
        _ordenarCitas();
      }
    } catch (e) {
      debugPrint('No se pudieron leer las citas: $e');
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

  Future<void> _guardarCitas() => _prefs.setString(
        _kCitas,
        jsonEncode(_citas.map((c) => c.toJson()).toList()),
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

  String nuevoId() => DateTime.now().microsecondsSinceEpoch.toString();

  // ---------------------------------------------------------------------------
  // Avisos
  // ---------------------------------------------------------------------------

  Future<void> _cola = Future<void>.value();

  /// Vuelve a programar todos los avisos. Las llamadas se hacen en fila
  /// para que dos reprogramaciones nunca se mezclen.
  Future<void> reprogramarAvisos() {
    final siguiente = _cola.then((_) async {
      try {
        await Notificaciones.instance.reprogramar(
          medicinas: List.of(_medicinas),
          citas: List.of(_citas),
          nombre: _nombre,
        );
      } catch (e) {
        debugPrint('No se pudieron programar los avisos: $e');
      }
    });
    _cola = siguiente;
    return siguiente;
  }

  // ---------------------------------------------------------------------------
  // Pastillas
  // ---------------------------------------------------------------------------

  Medicina? buscar(String id) {
    for (final m in _medicinas) {
      if (m.id == id) return m;
    }
    return null;
  }

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

  // ---------------------------------------------------------------------------
  // Tomas
  // ---------------------------------------------------------------------------

  DateTime? tomadaA(String medId, DateTime dia, int minutos) =>
      _tomas[claveToma(medId, dia, minutos)];

  /// Registra la toma. Devuelve false si todavía no es la hora
  /// (el botón "Ya me la tomé" se bloquea hasta la hora de la toma).
  Future<bool> marcarTomada(String medId, DateTime dia, int minutos) async {
    final clave = claveToma(medId, dia, minutos);
    if (_tomas.containsKey(clave)) return true; // ya estaba registrada
    if (!tomaDisponible(dia, minutos, DateTime.now())) return false;
    _tomas[clave] = DateTime.now();
    notifyListeners();
    await _guardarTomas();
    return true;
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

  // ---------------------------------------------------------------------------
  // Citas (consultas y laboratorios)
  // ---------------------------------------------------------------------------

  void _ordenarCitas() => _citas.sort((a, b) => a.fecha.compareTo(b.fecha));

  Cita? buscarCita(String id) {
    for (final c in _citas) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<void> guardarCita(Cita cita) async {
    final i = _citas.indexWhere((c) => c.id == cita.id);
    if (i >= 0) {
      _citas[i] = cita;
    } else {
      _citas.add(cita);
    }
    _ordenarCitas();
    notifyListeners();
    await _guardarCitas();
    await reprogramarAvisos();
  }

  Future<void> eliminarCita(String id) async {
    _citas.removeWhere((c) => c.id == id);
    notifyListeners();
    await _guardarCitas();
    await reprogramarAvisos();
  }

  /// Citas de un día, ordenadas por hora.
  List<Cita> citasDelDia(DateTime dia) =>
      _citas.where((c) => mismoDia(c.fecha, dia)).toList();

  /// Citas que todavía no pasan, de la más cercana a la más lejana.
  List<Cita> proximasCitas(DateTime ahora) =>
      _citas.where((c) => !c.yaPaso(ahora)).toList();
}
