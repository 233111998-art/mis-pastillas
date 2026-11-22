# Mis Pastillas · app para Sukey 💊

App sencilla en Flutter para que mamá no olvide sus pastillas y siempre pueda
revisar si ya se tomó una.

## Qué hace

- **Bienvenida** personalizada: "¡Bienvenida, Sukey!" con saludo según la hora.
- **Lista de pastillas** con dos tipos:
  - **Para siempre** (ej. Losartán): avisa todos los días a la misma hora.
  - **Por unos días** (ej. un antibiótico): eliges cuántos días (3, 5, 7… hasta 90)
    y desde qué día; al terminar deja de avisar sola.
  - Cada pastilla puede tener varias horas, dosis, notas ("con el desayuno") y un color.
- **Avisos** a la hora de cada toma, con el botón **"Ya me la tomé ✓"**:
  - Tocar el botón abre la app y la registra con la hora exacta.
  - Tocar el aviso abre la app y pregunta "¿Ya te tomaste tu pastilla?".
  - Si ya estaba registrada, la app le dice **"Ya te la tomaste a las 8:05 a. m. –
    No necesitas tomarla otra vez"** (para evitar dosis dobles).
- **Hoy**: avance del día (2 de 4), tomas pendientes, las que ya pasaron de hora
  y las tomadas con su hora.
- **Historial** de los últimos 14 días.
- Botón de **avisos** (campana arriba en "Hoy") para revisar permisos y mandar un aviso de prueba.

Todo se guarda en el teléfono (no necesita internet ni cuenta).
Está pensada para **Android**; en iPhone haría falta una Mac con Xcode y pasos extra.

## Cómo correrla

Necesitas Flutter 3.32 o más nuevo (`flutter --version`).

1. Descomprime la carpeta `sukey_pastillas` y abre una terminal dentro de ella.

2. Genera las carpetas de Android que faltan (no toca los archivos que ya vienen):

   ```bash
   flutter create --org com.familia --project-name sukey_pastillas --platforms android .
   ```

3. Activa el *desugaring* que pide el paquete de notificaciones:

   ```bash
   dart run tool/configurar_android.dart
   ```

   <details><summary>O hazlo a mano en <code>android/app/build.gradle.kts</code></summary>

   ```kotlin
   android {
       compileOptions {
           isCoreLibraryDesugaringEnabled = true   // ← agregar
           // ...lo que ya estaba
       }
   }

   dependencies {
       coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")   // ← agregar
   }
   ```
   </details>

4. Descarga paquetes y corre en el teléfono (con depuración USB activada):

   ```bash
   flutter pub get
   flutter run
   ```

5. Para instalarla en el teléfono de mamá:

   ```bash
   flutter build apk --release
   ```

   El archivo queda en `build/app/outputs/flutter-apk/app-release.apk`.
   Pásalo al teléfono e instálalo (pedirá permitir "instalar apps desconocidas").

## Primera vez en el teléfono de mamá

1. Abrir la app → **Comenzar** → aceptar **"Permitir notificaciones"**.
2. Agregar sus pastillas con **Agregar pastilla**.
3. Tocar la **campana** en "Hoy" → **Probar en 1 minuto**, salir de la app y esperar el aviso.
4. Si el aviso no llega (pasa mucho en Xiaomi, Motorola, Huawei, Oppo, Samsung):
   Ajustes del teléfono → Apps → Mis Pastillas → **Batería: Sin restricciones**
   (y en Xiaomi activar también **Inicio automático**).

## Personalizar

- Nombre: `lib/config.dart` → `kNombreUsuaria`.
- Colores: `lib/theme.dart` (clase `Cafe`).
- Nombre de la app en el teléfono: `android:label` en
  `android/app/src/main/AndroidManifest.xml`.

## Estructura

```
lib/
  main.dart                 arranque: carga datos y programa avisos
  app.dart                  MaterialApp + qué pasa al tocar un aviso
  config.dart               nombre de la usuaria
  theme.dart                paleta café y estilos
  models/medicina.dart      Medicina, Dosis y estados
  data/app_state.dart       guardado (shared_preferences) y registro de tomas
  services/notificaciones.dart  avisos programados (flutter_local_notifications)
  screens/                  bienvenida, hoy, mis pastillas, editar, historial
  widgets/                  hoja "¿Ya te la tomaste?", selector de hora, etc.
android/app/src/main/
  AndroidManifest.xml       permisos y receptores de avisos
  res/drawable/ic_notificacion.xml  icono de los avisos
  res/mipmap-*/             icono café de la app
```

## Si algo falla

- **`Dependency ... requires core library desugaring`** → falta el paso 3.
- **`requires compileSdk 36`** (o 35) → en `android/app/build.gradle.kts` cambia
  `compileSdk = flutter.compileSdkVersion` por `compileSdk = 36`.
- **No llegan los avisos** → revisa la campana en "Hoy" (los dos renglones deben decir
  "Listo") y la batería (ver arriba).
- **Gradle pide otra versión del Android Gradle Plugin** → en `android/settings.gradle.kts`
  sube la versión de `com.android.application` a la que indique el error (por ejemplo `8.11.1`).
- **Ya existía otra carpeta `android/`** → usa la de este proyecto: el `AndroidManifest.xml`
  y la carpeta `res/` de aquí son los que traen los permisos e iconos.

La fuente Nunito se incluye bajo la licencia SIL Open Font License (`assets/fonts/OFL.txt`).
