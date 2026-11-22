// Activa el "desugaring" que necesita flutter_local_notifications en
// android/app/build.gradle.kts (o build.gradle).
//
// Úsalo una sola vez, después de `flutter create --platforms android .`:
//
//   dart run tool/configurar_android.dart
//
// ignore_for_file: avoid_print

import 'dart:io';

const _versionDesugar = '2.1.4';

void main() {
  final kts = File('android/app/build.gradle.kts');
  final groovy = File('android/app/build.gradle');

  if (kts.existsSync()) {
    _parchear(kts, kotlin: true);
  } else if (groovy.existsSync()) {
    _parchear(groovy, kotlin: false);
  } else {
    stderr.writeln(
      'No encontré android/app/build.gradle.kts.\n'
      'Primero ejecuta en esta carpeta:\n'
      '  flutter create --org com.familia --project-name sukey_pastillas --platforms android .',
    );
    exitCode = 1;
  }
}

void _parchear(File archivo, {required bool kotlin}) {
  final original = archivo.readAsStringSync();
  var texto = original;

  final bandera = kotlin
      ? 'isCoreLibraryDesugaringEnabled = true'
      : 'coreLibraryDesugaringEnabled true';
  final dependencia = kotlin
      ? 'coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:$_versionDesugar")'
      : "coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:$_versionDesugar'";

  // 1) Bandera dentro de compileOptions { ... }
  if (!texto.contains('oreLibraryDesugaringEnabled')) {
    const marcador = 'compileOptions {';
    final i = texto.indexOf(marcador);
    if (i < 0) {
      stderr.writeln(
        'No encontré "compileOptions {" en ${archivo.path}.\n'
        'Agrega a mano dentro de android { compileOptions { ... } }:\n'
        '    $bandera',
      );
      exitCode = 1;
      return;
    }
    final fin = i + marcador.length;
    texto = texto.replaceRange(fin, fin, '\n        $bandera');
  }

  // 2) Dependencia al final del archivo
  if (!texto.contains('desugar_jdk_libs')) {
    texto = '${texto.trimRight()}\n\ndependencies {\n    $dependencia\n}\n';
  }

  if (texto == original) {
    print('✓ ${archivo.path} ya estaba configurado.');
    return;
  }

  archivo.writeAsStringSync(texto);
  print('✓ Listo: se activó el desugaring en ${archivo.path}');
}
