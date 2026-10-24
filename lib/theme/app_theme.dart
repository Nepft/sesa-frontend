import 'package:flutter/material.dart';

/// Token desain yang selaras dengan versi web SESA
/// (`frontend/src/styles/global.css`) — palet gelap terinspirasi Steam.
abstract final class AppColors {
  /// Latar dasar halaman (#171A21).
  static const Color background = Color(0xFF171A21);

  /// Permukaan panel/composer (#1B2838).
  static const Color surface = Color(0xFF1B2838);

  static const Color surfaceAlt = Color(0xFF23364A);
  static const Color inputBackground = Color(0xFF131A23);

  /// Aksen biru Steam (#66C0F4) untuk tombol utama dan sorotan.
  static const Color accent = Color(0xFF66C0F4);
  static const Color onAccent = Color(0xFF0B1116);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFFC7D5E0);
  static const Color textDim = Color(0xFF8F98A0);

  /// Garis hairline: rgba(199, 213, 224, 0.16).
  static const Color border = Color(0x29C7D5E0);

  /// Garis lebih tegas: rgba(199, 213, 224, 0.34).
  static const Color borderStrong = Color(0x57C7D5E0);

  static const Color positive = Color(0xFF56B870);
  static const Color positiveSoft = Color(0x1F56B870);
  static const Color negative = Color(0xFFE0685F);
  static const Color negativeSoft = Color(0x1FE0685F);

  static const double radius = 8;
  static const double radiusSmall = 4;

  /// Lebar maksimum konten hasil dan composer agar nyaman di layar lebar.
  static const double contentMaxWidth = 760;
}

/// Membuat tema gelap aplikasi dengan identitas visual Steam.
ThemeData buildAppTheme() {
  final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.accent,
      onPrimary: AppColors.onAccent,
      secondary: AppColors.accent,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      outline: AppColors.borderStrong,
      error: AppColors.negative,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      hintStyle: TextStyle(color: AppColors.textDim),
      isDense: true,
      contentPadding: EdgeInsets.zero,
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textMuted,
        side: const BorderSide(color: AppColors.borderStrong),
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusSmall),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accent,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.accent,
      linearMinHeight: 2,
    ),
  );
}

/// Durasi transisi halus (150-250 ms) yang dinolkan ketika pengguna meminta
/// reduksi animasi, sesuai RULES.md bagian 3.
Duration softTransition(BuildContext context) {
  return MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : const Duration(milliseconds: 200);
}

/// Gaya angka rapi (tabular) untuk statistik, counter, dan pagination.
const TextStyle kNumberStyle = TextStyle(
  fontFeatures: [FontFeature.tabularFigures()],
);
