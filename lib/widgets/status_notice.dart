import 'package:flutter/material.dart';

import '../controllers/analysis_controller.dart';
import '../theme/app_theme.dart';

/// Pesan status pada area hasil: backend belum terhubung, respons tidak valid,
/// atau galat lain. Bukan tempat menampilkan stack trace (RULES.md bagian 8).
class StatusNotice extends StatelessWidget {
  const StatusNotice({
    super.key,
    required this.message,
    this.onRetry,
    this.tone = NoticeTone.info,
  });

  final String message;

  /// Diisi bila pengguna dapat mengulang tindakan yang gagal.
  final VoidCallback? onRetry;

  final NoticeTone tone;

  @override
  Widget build(BuildContext context) {
    final isError = tone == NoticeTone.error;
    final color = isError ? AppColors.negative : AppColors.accent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppColors.radius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.cloud_off_outlined,
                size: 20,
                color: color,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          if (onRetry != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Coba lagi'),
              ),
            ),
        ],
      ),
    );
  }
}
