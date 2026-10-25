import 'package:flutter/material.dart';

import '../models/csv_analysis_result.dart';
import '../models/csv_review_row.dart';
import '../models/sentiment_label.dart';
import '../theme/app_theme.dart';

/// Tabel detail hasil CSV: header bagian, tombol unduh, baris hasil, dan
/// pagination.
///
/// Pagination membatasi baris yang dirender agar dataset besar tetap ringan
/// (RULES.md bagian 7).
class CsvResultTable extends StatefulWidget {
  const CsvResultTable({
    super.key,
    required this.result,
    required this.onExport,
    required this.isExporting,
  });

  final CsvAnalysisResult result;

  /// Memanggil `AnalysisController.exportResults`.
  final VoidCallback onExport;

  /// Mencegah tombol unduh ditekan berulang selama proses simpan berjalan.
  final bool isExporting;

  @override
  State<CsvResultTable> createState() => _CsvResultTableState();
}

class _CsvResultTableState extends State<CsvResultTable> {
  static const int _rowsPerPage = 10;

  int _page = 0;

  /// Dipakai untuk menggulir ke posisi teratas tabel saat halaman berganti.
  final GlobalKey _tableKey = GlobalKey();

  int get _rowCount => widget.result.rows.length;

  int get _pageCount {
    if (_rowCount == 0) return 1;
    return (_rowCount + _rowsPerPage - 1) ~/ _rowsPerPage;
  }

  List<CsvReviewRow> get _pageRows {
    final start = _page * _rowsPerPage;
    final rawEnd = start + _rowsPerPage;
    final end = rawEnd > _rowCount ? _rowCount : rawEnd;
    if (start >= end) return const [];
    return widget.result.rows.sublist(start, end);
  }

  @override
  void didUpdateWidget(covariant CsvResultTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.result, widget.result)) {
      _page = 0;
    }
  }

  void _changePage(int nextPage) {
    if (nextPage < 0 || nextPage >= _pageCount || nextPage == _page) return;
    setState(() => _page = nextPage);

    // Gulir halus ke atas tabel. Dijadwalkan setelah frame berikutnya agar
    // posisi baris terbaru sudah dihitung lebih dulu.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _tableKey.currentContext;
      if (context == null || !mounted) return;
      Scrollable.ensureVisible(
        context,
        duration: softTransition(context),
        curve: Curves.easeOut,
        alignment: 0,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final rows = _pageRows;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Detail per ulasan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Flexible agar tombol ikut mengecil (labelnya membungkus) ketika
            // layar sempit atau font dibesarkan, bukan memaksa overflow.
            Flexible(
              child: OutlinedButton.icon(
                onPressed: widget.isExporting || _rowCount == 0
                    ? null
                    : widget.onExport,
                icon: widget.isExporting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_rounded, size: 16),
                label: const Text('Unduh hasil'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_rowCount == 0)
          const Text(
            'Tidak ada baris hasil untuk ditampilkan.',
            style: TextStyle(fontSize: 13, color: AppColors.textDim),
          )
        else ...[
          _tableHeader(),
          for (final row in rows) _tableRow(row),
          const SizedBox(height: 18),
          _pagination(),
        ],
      ],
    );
  }

  Widget _tableHeader() {
    const style = TextStyle(
      fontSize: 12,
      letterSpacing: 0.4,
      fontWeight: FontWeight.w600,
      color: AppColors.textDim,
    );

    return Container(
      key: _tableKey,
      padding: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderStrong)),
      ),
      child: const Row(
        children: [
          SizedBox(width: 34, child: Text('No', style: style)),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: 12),
              child: Text('Ulasan', style: style),
            ),
          ),
          SizedBox(width: 60, child: Text('Sentimen', style: style)),
        ],
      ),
    );
  }

  Widget _tableRow(CsvReviewRow row) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 34,
            child: Text(
              '${row.rowNumber}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textDim,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                row.text,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
          SizedBox(width: 60, child: _SentimentTag(label: row.label)),
        ],
      ),
    );
  }

  Widget _pagination() {
    // FittedBox mengecilkannya bila skala font besar membuat baris melebihi
    // lebar layar, alih-alih memicu overflow.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OutlinedButton(
            onPressed: _page > 0 ? () => _changePage(_page - 1) : null,
            child: const Text('Sebelumnya'),
          ),
          const SizedBox(width: 14),
          Text(
            '${_page + 1} / $_pageCount',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textDim,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 14),
          OutlinedButton(
            onPressed: _page < _pageCount - 1
                ? () => _changePage(_page + 1)
                : null,
            child: const Text('Berikutnya'),
          ),
        ],
      ),
    );
  }
}

class _SentimentTag extends StatelessWidget {
  const _SentimentTag({required this.label});

  final SentimentLabel label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: label.softColor,
        borderRadius: BorderRadius.circular(AppColors.radiusSmall),
      ),
      child: Text(
        label.displayName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: label.color,
        ),
      ),
    );
  }
}
