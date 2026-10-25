import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'pulse_logo.dart';

/// Header ringkas berisi logo dan nama produk saja; tanpa link navigasi
/// karena aplikasi hanya memiliki satu halaman.
class AppNavbar extends StatelessWidget {
  const AppNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: const PulseLogo(size: 16),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'STEAM SENTIMENT '),
                  TextSpan(
                    text: 'ANALYZER',
                    style: TextStyle(color: AppColors.accent),
                  ),
                ],
              ),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.6,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
