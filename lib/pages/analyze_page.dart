import 'package:flutter/material.dart';

import '../controllers/analysis_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_navbar.dart';
import '../widgets/composer_card.dart';
import '../widgets/csv_result_table.dart';
import '../widgets/csv_summary_card.dart';
import '../widgets/hero_placeholder.dart';
import '../widgets/single_result_card.dart';
import '../widgets/status_notice.dart';

/// Satu-satunya halaman aplikasi.
///
/// Susunannya (lihat tangkapan layar versi web):
/// navbar tetap di atas → area hasil yang dapat digulir → composer menempel
/// di bawah beserta baris petunjuk.
class AnalyzePage extends StatefulWidget {
  const AnalyzePage({super.key, this.controller});

  /// Disuntikkan untuk pengujian. Bila kosong, halaman membuatnya sendiri
  /// dan bertanggung jawab melepasnya.
  final AnalysisController? controller;

  @override
  State<AnalyzePage> createState() => _AnalyzePageState();
}

class _AnalyzePageState extends State<AnalyzePage> {
  late final AnalysisController _controller;
  late final bool _ownsController;
  final ScrollController _resultScroll = ScrollController();

  Object? _lastResult;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? AnalysisController();
    _lastResult = _controller.currentResult;
    _controller.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    if (_ownsController) _controller.dispose();
    _resultScroll.dispose();
    super.dispose();
  }

  /// Ketika hasil baru muncul, kembali ke bagian atas area hasil agar judul
  /// "Hasil Analisis" langsung terlihat.
  void _handleControllerChanged() {
    final result = _controller.currentResult;
    if (identical(result, _lastResult)) return;
    _lastResult = result;
    if (result == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_resultScroll.hasClients) return;
      _resultScroll.animateTo(
        0,
        duration: softTransition(context),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            return Column(
              children: [
                const AppNavbar(),
                Expanded(child: _buildResultArea()),
                _buildDock(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildResultArea() {
    final notice = _controller.notice;

    return SingleChildScrollView(
      controller: _resultScroll,
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 28),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppColors.contentMaxWidth,
          ),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (notice != null) ...[
                  StatusNotice(
                    message: notice.message,
                    tone: notice.tone,
                    onRetry: notice.retry == null
                        ? null
                        : () => _controller.retry(),
                  ),
                  const SizedBox(height: 24),
                ],
                if (_controller.csvResult != null) ...[
                  CsvSummaryCard(result: _controller.csvResult!),
                  const SizedBox(height: 36),
                  CsvResultTable(
                    result: _controller.csvResult!,
                    isExporting: _controller.isExporting,
                    onExport: _controller.exportResults,
                  ),
                ] else if (_controller.singleResult != null)
                  SingleResultCard(result: _controller.singleResult!)
                else if (notice == null)
                  Center(child: HeroPlaceholder()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDock() {
    final hint = _controller.attachment != null
        ? 'Hapus lampiran untuk menulis ulasan'
        : 'CSV · kolom content · maks 5 MB · Enter kirim';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppColors.contentMaxWidth,
          ),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ComposerCard(controller: _controller),
                const SizedBox(height: 8),
                Text(
                  hint,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textDim,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
