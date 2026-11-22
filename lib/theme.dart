import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Paleta café de la app.
class Cafe {
  Cafe._();

  static const Color espresso = Color(0xFF3B2A20); // texto fuerte / fondos oscuros
  static const Color cafe = Color(0xFF6F4E37); // color principal
  static const Color cafeMedio = Color(0xFF8B6447);
  static const Color caramelo = Color(0xFFC08552); // acento
  static const Color latte = Color(0xFFEAD9C6); // contenedores suaves
  static const Color crema = Color(0xFFF7F0E8); // fondo de pantallas
  static const Color espuma = Color(0xFFFFFBF6); // tarjetas
  static const Color borde = Color(0xFFE3D3C2);
  static const Color textoSuave = Color(0xFF7D6656);

  static const Color verde = Color(0xFF5E7F4F); // tomada
  static const Color verdeClaro = Color(0xFFE4EDDA);
  static const Color ambar = Color(0xFFB7791F); // ya pasó la hora
  static const Color ambarClaro = Color(0xFFF7E8CF);
  static const Color rojo = Color(0xFFA4493D);
  static const Color rojoClaro = Color(0xFFF5E0DC);

  /// Colores para distinguir cada pastilla.
  static const List<Color> pastillas = [
    Color(0xFF6F4E37), // café
    Color(0xFFC08552), // caramelo
    Color(0xFF7A8B5C), // olivo
    Color(0xFFB5654A), // terracota
    Color(0xFF5F7486), // pizarra
    Color(0xFFC48A9A), // rosa palo
  ];

  static Color colorPastilla(int indice) =>
      pastillas[indice.abs() % pastillas.length];

  static const LinearGradient degradado = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [espresso, cafe],
  );
}

/// Iconos claros en la barra de estado (para los encabezados café).
const SystemUiOverlayStyle estiloBarraClara = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
);

ThemeData construirTema() {
  final esquema = ColorScheme.fromSeed(
    seedColor: Cafe.cafe,
    brightness: Brightness.light,
  ).copyWith(
    primary: Cafe.cafe,
    onPrimary: Colors.white,
    primaryContainer: Cafe.latte,
    onPrimaryContainer: Cafe.espresso,
    secondary: Cafe.caramelo,
    onSecondary: Colors.white,
    secondaryContainer: const Color(0xFFF3E1CD),
    onSecondaryContainer: Cafe.espresso,
    surface: Cafe.crema,
    onSurface: Cafe.espresso,
    onSurfaceVariant: Cafe.textoSuave,
    outline: Cafe.borde,
    outlineVariant: Cafe.borde,
    error: Cafe.rojo,
  );

  const radio = BorderRadius.all(Radius.circular(18));

  final botonGrande = ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(Size(64, 58)),
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: 22, vertical: 14),
    ),
    shape: const WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: radio),
    ),
    textStyle: const WidgetStatePropertyAll(
      TextStyle(
        fontFamily: 'Nunito',
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  return ThemeData(
    colorScheme: esquema,
    scaffoldBackgroundColor: Cafe.crema,
    fontFamily: 'Nunito',
    textTheme: const TextTheme(
      displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w800),
      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
      headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
      titleMedium: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
      titleSmall: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      bodyLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      bodySmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      labelLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      labelMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
    ).apply(bodyColor: Cafe.espresso, displayColor: Cafe.espresso),
    filledButtonTheme: FilledButtonThemeData(style: botonGrande),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: botonGrande.copyWith(
        side: const WidgetStatePropertyAll(
          BorderSide(color: Cafe.cafe, width: 1.6),
        ),
        foregroundColor: const WidgetStatePropertyAll(Cafe.cafe),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: const WidgetStatePropertyAll(Cafe.cafe),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(
            fontFamily: 'Nunito',
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: radio),
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Cafe.cafe,
      foregroundColor: Colors.white,
      extendedTextStyle: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 17,
        fontWeight: FontWeight.w800,
      ),
      shape: RoundedRectangleBorder(borderRadius: radio),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      labelStyle: TextStyle(color: Cafe.textoSuave, fontSize: 17),
      hintStyle: TextStyle(color: Color(0xFFB09A88), fontSize: 17),
      border: OutlineInputBorder(
        borderRadius: radio,
        borderSide: BorderSide(color: Cafe.borde),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radio,
        borderSide: BorderSide(color: Cafe.borde, width: 1.4),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radio,
        borderSide: BorderSide(color: Cafe.cafe, width: 2),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Cafe.espuma,
      indicatorColor: Cafe.latte,
      height: 76,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (estados) => TextStyle(
          fontFamily: 'Nunito',
          fontSize: 14,
          fontWeight: estados.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w600,
          color: estados.contains(WidgetState.selected)
              ? Cafe.espresso
              : Cafe.textoSuave,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (estados) => IconThemeData(
          size: 28,
          color: estados.contains(WidgetState.selected)
              ? Cafe.cafe
              : Cafe.textoSuave,
        ),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Cafe.espresso,
      contentTextStyle: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      actionTextColor: Cafe.latte,
      shape: RoundedRectangleBorder(borderRadius: radio),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Cafe.espuma,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: Cafe.borde,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Cafe.espuma,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(28))),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(64, 56)),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(
            fontFamily: 'Nunito',
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (estados) =>
              estados.contains(WidgetState.selected) ? Cafe.cafe : Colors.white,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (estados) => estados.contains(WidgetState.selected)
              ? Colors.white
              : Cafe.espresso,
        ),
        side: const WidgetStatePropertyAll(BorderSide(color: Cafe.borde, width: 1.4)),
      ),
    ),
    dividerTheme: const DividerThemeData(color: Cafe.borde, thickness: 1),
  );
}
