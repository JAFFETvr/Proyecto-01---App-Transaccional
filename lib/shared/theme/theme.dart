import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

// ────────────────────────────────────────────────────────────────────────────
// ToolShare – ThemeData "Fintech Industrial"
// ────────────────────────────────────────────────────────────────────────────

class MaterialTheme {
  final TextTheme textTheme;
  const MaterialTheme(this.textTheme);

  // ── Esquemas de color ─────────────────────────────────────────────────────

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      // Primario = naranja ToolShare
      primary: AppColors.orange500,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFFFEDD5),
      onPrimaryContainer: Color(0xFF7C2D12),
      // Secundario = Slate medium
      secondary: AppColors.slate600,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.slate100,
      onSecondaryContainer: AppColors.slate900,
      // Terciario = Success verde
      tertiary: AppColors.success,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.successBg,
      onTertiaryContainer: Color(0xFF064E3B),
      // Error = Danger rojo
      error: AppColors.danger,
      onError: Colors.white,
      errorContainer: AppColors.dangerBg,
      onErrorContainer: Color(0xFF7F1D1D),
      // Superficie
      surface: AppColors.surface,
      onSurface: AppColors.slate900,
      onSurfaceVariant: AppColors.slate600,
      outline: AppColors.slate300,
      outlineVariant: Color(0xFFE2E8F0),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: AppColors.slate900,
      inversePrimary: AppColors.orange500,
      // Surface containers
      surfaceTint: AppColors.orange500,
      surfaceDim: Color(0xFFE2E8F0),
      surfaceBright: AppColors.surface,
      surfaceContainerLowest: AppColors.background,
      surfaceContainerLow: Color(0xFFF1F5F9),
      surfaceContainer: Color(0xFFE2E8F0),
      surfaceContainerHigh: Color(0xFFCBD5E1),
      surfaceContainerHighest: Color(0xFFB8C4D3),
    );
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.orange500,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFF7C2D12),
      onPrimaryContainer: Color(0xFFFFEDD5),
      secondary: Color(0xFF94A3B8),
      onSecondary: AppColors.slate900,
      secondaryContainer: Color(0xFF1E293B),
      onSecondaryContainer: Color(0xFFCBD5E1),
      tertiary: AppColors.success,
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFF064E3B),
      onTertiaryContainer: Color(0xFFD1FAE5),
      error: Color(0xFFFCA5A5),
      onError: Color(0xFF7F1D1D),
      errorContainer: Color(0xFF7F1D1D),
      onErrorContainer: Color(0xFFFEE2E2),
      surface: Color(0xFF0F172A),
      onSurface: Color(0xFFE2E8F0),
      onSurfaceVariant: Color(0xFF94A3B8),
      outline: Color(0xFF334155),
      outlineVariant: Color(0xFF1E293B),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Color(0xFFE2E8F0),
      inversePrimary: AppColors.orange600,
      surfaceTint: AppColors.orange500,
      surfaceDim: Color(0xFF0F172A),
      surfaceBright: Color(0xFF1E293B),
      surfaceContainerLowest: Color(0xFF020617),
      surfaceContainerLow: Color(0xFF0F172A),
      surfaceContainer: Color(0xFF1E293B),
      surfaceContainerHigh: Color(0xFF334155),
      surfaceContainerHighest: Color(0xFF475569),
    );
  }

  // ── Fábrica de ThemeData ──────────────────────────────────────────────────

  ThemeData light() => _buildTheme(lightScheme());
  ThemeData dark()  => _buildTheme(darkScheme());

  ThemeData _buildTheme(ColorScheme cs) {
    // Tipografía: Montserrat para display/títulos · Inter para cuerpo/labels
    final base = textTheme;
    final displayFont = GoogleFonts.montserratTextTheme(base);
    final bodyFont    = GoogleFonts.interTextTheme(base);

    final mergedText = displayFont.copyWith(
      // Títulos grandes → Montserrat Bold
      displayLarge:  displayFont.displayLarge?.copyWith(fontWeight: FontWeight.w700),
      displayMedium: displayFont.displayMedium?.copyWith(fontWeight: FontWeight.w700),
      displaySmall:  displayFont.displaySmall?.copyWith(fontWeight: FontWeight.w700),
      headlineLarge: displayFont.headlineLarge?.copyWith(fontWeight: FontWeight.w800, color: cs.onSurface),
      headlineMedium:displayFont.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
      headlineSmall: displayFont.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      titleLarge:    displayFont.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium:   displayFont.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall:    displayFont.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      // Cuerpo y labels → Inter Regular/Medium
      bodyLarge:   bodyFont.bodyLarge,
      bodyMedium:  bodyFont.bodyMedium,
      bodySmall:   bodyFont.bodySmall,
      labelLarge:  bodyFont.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      labelMedium: bodyFont.labelMedium,
      labelSmall:  bodyFont.labelSmall,
    ).apply(
      bodyColor:    cs.onSurface,
      displayColor: cs.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: cs.brightness,
      colorScheme: cs,
      textTheme: mergedText,

      // ── Scaffold ──────────────────────────────────────────────────────────
      scaffoldBackgroundColor: cs.brightness == Brightness.light
          ? AppColors.background
          : const Color(0xFF0F172A),

      // ── AppBar ────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: cs.brightness == Brightness.light
            ? AppColors.surface
            : const Color(0xFF0F172A),
        foregroundColor: cs.brightness == Brightness.light
            ? AppColors.slate900
            : const Color(0xFFE2E8F0),
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: GoogleFonts.montserrat(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: cs.brightness == Brightness.light
              ? AppColors.slate900
              : const Color(0xFFE2E8F0),
        ),
      ),

      // ── Card ──────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: cs.brightness == Brightness.light
            ? AppColors.surface
            : const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        // La sombra se añade manualmente en cada Card para mayor control.
        clipBehavior: Clip.antiAlias,
      ),

      // ── FilledButton (no se usa directo en botones principales) ───────────
      // Los botones primarios usan Container+Gradient; FilledButton se reserva
      // para acciones secundarias: success verde, etc.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ── OutlinedButton ────────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          side: BorderSide(color: cs.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      // ── TextButton ────────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.orange500,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // ── InputDecoration ───────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.brightness == Brightness.light
            ? AppColors.surface
            : const Color(0xFF1E293B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.orange500, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
        hintStyle: GoogleFonts.inter(
          color: AppColors.slate600.withOpacity(0.5),
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.inter(color: AppColors.slate600, fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        prefixIconColor: AppColors.slate600,
      ),

      // ── Chip ──────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.slate100,
        selectedColor: AppColors.orange500.withOpacity(0.12),
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // ── Divider ───────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE2E8F0),
        thickness: 1,
        space: 1,
      ),

      // ── SnackBar ──────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.slate900,
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 14),
      ),

      // ── FloatingActionButton ──────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.orange500,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
      ),

      // ── ListTile ──────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // Métodos de compatibilidad (no se usan en el MVP pero los conservamos)
  ThemeData lightMediumContrast() => light();
  ThemeData lightHighContrast()   => light();
  ThemeData darkMediumContrast()  => dark();
  ThemeData darkHighContrast()    => dark();

  List<ExtendedColor> get extendedColors => [];
}

// ────────────────────────────────────────────────────────────────────────────
// Clases auxiliares (se mantienen por compatibilidad con código existente)
// ────────────────────────────────────────────────────────────────────────────

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}
