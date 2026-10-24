import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'pulse_logo.dart';

/// Tampilan awal sebelum ada hasil: ikon dan judul utama.
///
/// Widget ini hanya tampil ketika belum ada hasil analisis; begitu hasil
/// muncul, area hasil menggantikannya (lihat `AnalyzePage`).
class HeroPlaceholder extends StatelessWidget {
  const HeroPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: const PulseLogo(size: 30),
        ),
        const SizedBox(height: 22),
        const Text(
          'Analisis Sentimen Ulasan Steam',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            height: 1.35,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
