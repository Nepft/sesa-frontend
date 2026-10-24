import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Chip lampiran pada komposer: nama file, ukuran, dan tombol lepas.
class AttachmentChip extends StatelessWidget {
  const AttachmentChip({
    super.key,
    required this.fileName,
    required this.fileSizeBytes,
    required this.onRemove,
    this.removable = true,
  });

  final String fileName;
  final int fileSizeBytes;
  final VoidCallback? onRemove;

  /// Nonaktif selama analisis berjalan agar lampiran tidak dilepas di tengah
  /// proses.
  final bool removable;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(AppColors.radiusSmall),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.insert_drive_file_outlined,
            size: 20,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatFileSize(fileSizeBytes),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textDim,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          if (removable)
            IconButton(
              onPressed: onRemove,
              tooltip: 'Lepaskan file',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close_rounded, size: 18),
              color: AppColors.textDim,
            ),
        ],
      ),
    );
  }

  /// Format ukuran singkat, mis. `198 KB` atau `1.2 MB`.
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    const kb = 1024;
    const mb = kb * 1024;
    if (bytes < mb) {
      final value = bytes / kb;
      return '${value >= 100 ? value.round() : value.toStringAsFixed(1)} KB';
    }
    return '${(bytes / mb).toStringAsFixed(1)} MB';
  }
}
