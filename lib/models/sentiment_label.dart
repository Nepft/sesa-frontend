import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Kelas sentimen sesuai label model.
///
/// Hanya dua nilai. Menambah kelas (misalnya "Netral") dilarang tanpa
/// konfirmasi dari model final — lihat RULES.md bagian 1 dan 7.
enum SentimentLabel {
  positif('Positif'),
  negatif('Negatif');

  const SentimentLabel(this.displayName);

  /// Label yang ditampilkan ke pengguna, sekaligus nilai yang diharapkan dari
  /// respons backend.
  final String displayName;

  /// Warna status. Selalu ditemani [displayName] agar warna bukan satu-satunya
  /// indikator hasil (RULES.md bagian 3 dan 8).
  Color get color => switch (this) {
    SentimentLabel.positif => AppColors.positive,
    SentimentLabel.negatif => AppColors.negative,
  };

  /// Warna latar lembut untuk chip/ikon sentimen.
  Color get softColor => switch (this) {
    SentimentLabel.positif => AppColors.positiveSoft,
    SentimentLabel.negatif => AppColors.negativeSoft,
  };

  IconData get icon => switch (this) {
    SentimentLabel.positif => Icons.check_rounded,
    SentimentLabel.negatif => Icons.close_rounded,
  };

  /// Membaca label dari respons backend.
  ///
  /// Pemetaan label dikunci di lapisan model (bukan di widget) sesuai RULES.md
  /// bagian 7. Mengembalikan `null` bila label tidak dikenali, agar memicu
  /// error skema yang jujur alih-alih menebak hasil.
  static SentimentLabel? tryParse(Object? raw) {
    if (raw is! String) return null;
    return switch (raw.trim().toLowerCase()) {
      'positif' || 'positive' => SentimentLabel.positif,
      'negatif' || 'negative' => SentimentLabel.negatif,
      _ => null,
    };
  }
}
