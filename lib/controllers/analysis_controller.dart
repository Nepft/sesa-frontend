import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';

import '../models/csv_analysis_result.dart';
import '../models/single_analysis_result.dart';
import '../services/api_config.dart';
import '../services/csv_export_service.dart';
import '../services/csv_file_service.dart';
import '../services/sentiment_api_service.dart';

/// Tahap pengiriman analisis.
enum AnalysisPhase { idle, loading }

/// Tindakan yang dapat diulang dari pesan status di area hasil.
enum NoticeRetry { text, csv, export }

/// Nada pesan status pada area hasil.
///
/// `info` untuk masalah koneksi/endpoint (server memang belum tersedia),
/// `error` untuk galat server atau respons yang tidak sah.
enum NoticeTone { info, error }

/// Pesan status/galat pada area hasil.
class AnalysisNotice {
  const AnalysisNotice(
    this.message, {
    this.retry,
    this.tone = NoticeTone.error,
  });

  final String message;

  /// Diisi bila pengguna dapat mengulang tindakan yang gagal.
  final NoticeRetry? retry;

  final NoticeTone tone;
}

/// Lampiran CSV yang sudah lolos validasi dan parsing, tetapi belum dianalisis.
class CsvAttachment {
  const CsvAttachment({
    required this.fileName,
    required this.fileSizeBytes,
    required this.bytes,
    required this.parsed,
  });

  final String fileName;
  final int fileSizeBytes;

  /// Isi file asli yang dikirim ke `POST /predict/batch`.
  final Uint8List bytes;

  final ParsedCsvFile parsed;
}

/// State dan aksi kedua alur analisis (satu teks dan file CSV).
///
/// Memakai `ChangeNotifier` bawaan Flutter sebagai state management paling
/// sederhana, tanpa framework tambahan (RULES.md bagian 4).
///
/// Prinsip yang dijaga:
/// - Teks pengguna dikosongkan hanya setelah analisis berhasil; saat gagal
///   teks tetap tersimpan.
/// - Hasil selalu berasal dari respons backend; tidak ada nilai prediksi
///   buatan. Kegagalan ditampilkan sebagai [notice], bukan sebagai hasil.
class AnalysisController extends ChangeNotifier {
  AnalysisController({
    SentimentApiService? apiService,
    CsvFileService? csvFileService,
    CsvExportService? csvExportService,
  }) : _api = apiService ?? SentimentApiService(),
       _csvFiles = csvFileService ?? const CsvFileService(),
       _csvExports = csvExportService ?? const CsvExportService();

  final SentimentApiService _api;
  final CsvFileService _csvFiles;
  final CsvExportService _csvExports;

  /// Field teks dimiliki controller agar teks dapat dikosongkan otomatis
  /// setelah sukses dan tetap tersimpan saat gagal.
  final TextEditingController textController = TextEditingController();

  AnalysisPhase _phase = AnalysisPhase.idle;
  SingleAnalysisResult? _singleResult;
  CsvAnalysisResult? _csvResult;
  CsvAttachment? _attachment;
  String? _composerMessage;
  AnalysisNotice? _notice;
  bool _isExporting = false;
  bool _disposed = false;

  AnalysisPhase get phase => _phase;
  bool get isLoading => _phase == AnalysisPhase.loading;
  bool get isExporting => _isExporting;

  SingleAnalysisResult? get singleResult => _singleResult;
  CsvAnalysisResult? get csvResult => _csvResult;

  /// Hanya satu jenis hasil yang tampil; jenis terbaru menang.
  Object? get currentResult => _csvResult ?? _singleResult;
  bool get hasAnyResult => currentResult != null;

  CsvAttachment? get attachment => _attachment;

  /// Validasi/kesalahan yang ditampilkan dekat komposer.
  String? get composerMessage => _composerMessage;

  /// Status atau galat yang ditampilkan di area hasil.
  AnalysisNotice? get notice => _notice;

  /// Tombol kirim aktif bila ada isi yang bisa dikirim dan tidak sedang proses.
  bool get canSubmit =>
      !isLoading && (_attachment != null || textController.text.isNotEmpty);

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> analyzeText() async {
    if (isLoading) return;

    final text = textController.text;
    final validationError = validateText(text);
    if (validationError != null) {
      _composerMessage = validationError;
      _notice = null;
      _notify();
      return;
    }

    _composerMessage = null;
    _notice = null;
    _phase = AnalysisPhase.loading;
    _notify();

    try {
      final result = await _api.predictText(text);
      _singleResult = result;
      _csvResult = null;
      _phase = AnalysisPhase.idle;
      // Teks hanya dikosongkan setelah analisis sukses.
      textController.clear();
    } on BackendUnavailableException catch (error) {
      _phase = AnalysisPhase.idle;
      _notice = AnalysisNotice(
        error.message,
        retry: NoticeRetry.text,
        tone: NoticeTone.info,
      );
    } on SentimentApiException catch (error) {
      _phase = AnalysisPhase.idle;
      _notice = AnalysisNotice(error.message, retry: NoticeRetry.text);
    }
    _notify();
  }

  /// Memvalidasi teks ulasan tanpa memanggil backend.
  static String? validateText(String text) {
    if (text.trim().isEmpty) {
      return 'Tulis ulasan terlebih dahulu.';
    }
    if (text.length > ApiConfig.maxTextLength) {
      return 'Ulasan terlalu panjang. Maksimal ${ApiConfig.maxTextLength} '
          'karakter.';
    }
    return null;
  }

  /// Membuka pemilih file dan memproses file yang dipilih.
  ///
  /// Urutannya sengaja: ukuran dulu (bila platform melaporkannya) agar file
  /// yang melampaui batas tidak sempat dimuat ke memori, lalu isi file dibaca
  /// dan divalidasi strukturnya.
  Future<void> pickCsvFile() async {
    if (isLoading) return;

    final List<PlatformFile> selection;
    try {
      selection = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['csv'],
      );
    } on Exception {
      _composerMessage = 'File tidak dapat dipilih. Coba pilih ulang.';
      _notify();
      return;
    }

    // Daftar kosong berarti pengguna membatalkan pilihan; tidak ada yang
    // berubah.
    if (selection.isEmpty) return;

    final file = selection.first;

    int? reportedSize;
    try {
      reportedSize = file.lengthSync() ?? await file.length();
    } on Exception {
      reportedSize = null;
    }

    if (reportedSize != null) {
      final earlyError = _csvFiles.validateFile(
        fileName: file.name,
        fileSizeBytes: reportedSize,
      );
      if (earlyError != null) {
        _composerMessage = earlyError;
        _notify();
        return;
      }
    }

    final Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } on Exception {
      _composerMessage =
          'File tidak dapat dibaca. Pilih file lain, lalu coba lagi.';
      _notify();
      return;
    }

    attachCsvFile(
      fileName: file.name,
      fileSizeBytes: reportedSize ?? bytes.length,
      bytes: bytes,
    );
  }

  /// Memvalidasi dan mem-parsing file CSV yang sudah dibaca.
  ///
  /// Terpisah dari [pickCsvFile] agar logika validasi dapat diuji tanpa
  /// platform channel pemilih file.
  void attachCsvFile({
    required String fileName,
    required int fileSizeBytes,
    required Uint8List bytes,
  }) {
    final metaError = _csvFiles.validateFile(
      fileName: fileName,
      fileSizeBytes: fileSizeBytes,
    );
    if (metaError != null) {
      _composerMessage = metaError;
      _notify();
      return;
    }

    try {
      final parsed = _csvFiles.parseBytes(bytes);
      _attachment = CsvAttachment(
        fileName: fileName,
        fileSizeBytes: fileSizeBytes,
        bytes: bytes,
        parsed: parsed,
      );
      _composerMessage = null;
    } on CsvFileException catch (error) {
      _composerMessage = error.message;
    }
    _notify();
  }

  Future<void> analyzeCsv() async {
    final attachment = _attachment;
    if (attachment == null || isLoading) return;

    _composerMessage = null;
    _notice = null;
    _phase = AnalysisPhase.loading;
    _notify();

    try {
      final result = await _api.analyzeCsv(
        fileName: attachment.fileName,
        bytes: attachment.bytes,
        parsed: attachment.parsed,
      );
      _csvResult = result;
      _singleResult = null;
      _phase = AnalysisPhase.idle;
    } on BackendUnavailableException catch (error) {
      _phase = AnalysisPhase.idle;
      _notice = AnalysisNotice(
        error.message,
        retry: NoticeRetry.csv,
        tone: NoticeTone.info,
      );
    } on SentimentApiException catch (error) {
      _phase = AnalysisPhase.idle;
      _notice = AnalysisNotice(error.message, retry: NoticeRetry.csv);
    }
    _notify();
  }

  /// Melepas lampiran agar pengguna bisa menulis ulasan atau memilih file lain.
  /// Hasil analisis yang sudah tampil tetap dipertahankan.
  void clearAttachment() {
    if (isLoading) return;
    _attachment = null;
    _composerMessage = null;
    _notify();
  }

  /// Mengirim sesuai konteks komposer: lampiran CSV atau teks ulasan.
  Future<void> submit() {
    if (_attachment != null) return analyzeCsv();
    return analyzeText();
  }

  /// Mengulang tindakan yang gagal, dipakai tombol "Coba lagi".
  Future<void> retry() {
    switch (_notice?.retry) {
      case NoticeRetry.text:
        return analyzeText();
      case NoticeRetry.csv:
        return analyzeCsv();
      case NoticeRetry.export:
        return exportResults();
      case null:
        return Future<void>.value();
    }
  }

  /// Dipanggil setiap teks berubah agar counter dan pesan validasi ikut
  /// menyesuaikan; pesan validasi lama hilang begitu pengguna mengedit.
  void onTextChanged() {
    if (_composerMessage != null) _composerMessage = null;
    _notify();
  }

  /// Menyimpan seluruh baris hasil ke file CSV.
  ///
  /// Pembatalan dialog pengguna bukan kegagalan. Kegagalan platform
  /// ditampilkan sebagai [notice], bukan sebagai hasil unduhan sukses.
  Future<void> exportResults() async {
    final result = _csvResult;
    if (result == null || result.rows.isEmpty || _isExporting) return;

    _isExporting = true;
    _notice = null;
    _notify();

    try {
      final bytes = Uint8List.fromList(
        utf8.encode(_csvExports.buildCsv(result)),
      );
      await FilePicker.saveFile(
        fileName: _csvExports.buildFileName(result),
        bytes: bytes,
        mimeType: 'text/csv',
      );
    } on Exception {
      _notice = const AnalysisNotice(
        'Gagal menyimpan hasil. Coba lagi.',
        retry: NoticeRetry.export,
      );
    } finally {
      _isExporting = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    textController.dispose();
    super.dispose();
  }
}
