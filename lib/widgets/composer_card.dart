import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/analysis_controller.dart';
import '../services/api_config.dart';
import '../theme/app_theme.dart';
import 'attachment_chip.dart';

/// Composer tetap di bagian bawah layar: satu tempat untuk menulis ulasan
/// maupun melampirkan file CSV (tanpa pemilihan mode/tab).
///
/// Perilaku yang dijaga:
/// - Enter mengirim, Shift+Enter menyisipkan baris baru (pada papan ketik
///   fisik; papan ketik layar tetap menghasilkan baris baru).
/// - Tersedia counter karakter dan garis progres tipis saat analisis berjalan.
/// - Ada lampiran: input teks tidak ditampilkan sampai lampiran dilepas.
class ComposerCard extends StatefulWidget {
  const ComposerCard({super.key, required this.controller});

  final AnalysisController controller;

  @override
  State<ComposerCard> createState() => _ComposerCardState();
}

class _ComposerCardState extends State<ComposerCard> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(onKeyEvent: _handleKeyEvent);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey != LogicalKeyboardKey.enter) {
      return KeyEventResult.ignored;
    }
    if (HardwareKeyboard.instance.isShiftPressed) {
      return KeyEventResult.ignored;
    }
    if (!widget.controller.canSubmit) return KeyEventResult.ignored;

    widget.controller.submit();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final attachment = controller.attachment;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppColors.radius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (controller.isLoading) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (attachment != null) ...[
                  AttachmentChip(
                    fileName: attachment.fileName,
                    fileSizeBytes: attachment.fileSizeBytes,
                    removable: !controller.isLoading,
                    onRemove: controller.clearAttachment,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'File CSV terlampir.',
                    style: TextStyle(fontSize: 14, color: AppColors.textDim),
                  ),
                ] else ...[
                  TextField(
                    controller: controller.textController,
                    focusNode: _focusNode,
                    minLines: 3,
                    maxLines: 6,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    onChanged: (_) => controller.onTextChanged(),
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: AppColors.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Tulis ulasan Steam...',
                    ),
                  ),
                ],
                if (controller.composerMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    controller.composerMessage!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: AppColors.negative,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
            child: _ComposerActions(controller: controller),
          ),
        ],
      ),
    );
  }
}

/// Baris bawah komposer: lampiran, counter karakter, dan tombol kirim.
class _ComposerActions extends StatelessWidget {
  const _ComposerActions({required this.controller});

  final AnalysisController controller;

  @override
  Widget build(BuildContext context) {
    final attachment = controller.attachment;
    final counter = controller.textController.text.length;
    final overLimit = counter > ApiConfig.maxTextLength;

    return Row(
      children: [
        IconButton(
          onPressed: controller.isLoading ? null : controller.pickCsvFile,
          tooltip: 'Lampirkan file CSV',
          icon: const Icon(Icons.attach_file_rounded, size: 20),
          color: AppColors.textMuted,
          disabledColor: AppColors.textDim,
        ),
        const Spacer(),
        if (attachment == null && counter > 0) ...[
          Text(
            '$counter / ${ApiConfig.maxTextLength}',
            style: TextStyle(
              fontSize: 12,
              color: overLimit ? AppColors.negative : AppColors.textDim,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 10),
        ],
        _SendButton(controller: controller),
      ],
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.controller});

  final AnalysisController controller;

  @override
  Widget build(BuildContext context) {
    final enabled = controller.canSubmit;

    return IconButton(
      onPressed: enabled ? controller.submit : null,
      tooltip: controller.attachment != null
          ? 'Analisis file CSV'
          : 'Kirim ulasan',
      style: IconButton.styleFrom(
        backgroundColor: enabled ? AppColors.accent : AppColors.surfaceAlt,
        foregroundColor: enabled ? AppColors.onAccent : AppColors.textDim,
        minimumSize: const Size(38, 38),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusSmall),
        ),
      ),
      icon: const Icon(Icons.arrow_upward_rounded, size: 20),
    );
  }
}
