import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';

import 'api_config.dart';

/// Alasan sebuah file CSV ditolak sebelum dikirim ke backend.
///
/// Pesannya sudah berbahasa Indonesia dan dapat ditindaklanjuti pengguna.
class CsvFileException implements Exception {
  const CsvFileException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Satu baris teks siap analisis, dinomori sesuai posisinya di file sumber.
class CsvTextRow {
  const CsvTextRow({required this.rowNumber, required this.text});

  final int rowNumber;
  final String text;
}

/// Hasil parsing file CSV yang lolos validasi.
class ParsedCsvFile {
  const ParsedCsvFile({required this.totalRows, required this.validRows});

  /// Jumlah baris data pada file (tidak termasuk header).
  final int totalRows;

  /// Baris yang kolom teksnya berisi dan siap dikirim.
  final List<CsvTextRow> validRows;

  /// Baris yang dilewati karena kolom teksnya kosong.
  int get skippedRows => totalRows - validRows.length;
}

/// Validasi dan pembacaan file CSV sesuai kontrak kolom [ApiConfig.expectedColumn].
class CsvFileService {
  const CsvFileService();

  /// Memvalidasi ekstensi dan ukuran file; mengembalikan pesan galat, atau
  /// `null` bila file lolos.
  String? validateFile({required String fileName, required int fileSizeBytes}) {
    if (!fileName.toLowerCase().endsWith('.csv')) {
      return 'Format file harus .csv. Pilih file dengan ekstensi .csv.';
    }
    if (fileSizeBytes > ApiConfig.maxFileSizeBytes) {
      final maxMb = ApiConfig.maxFileSizeBytes / (1024 * 1024);
      return 'Ukuran file maksimal ${maxMb.toStringAsFixed(0)} MB. File yang '
          'dipilih terlalu besar.';
    }
    if (fileSizeBytes == 0) {
      return 'File kosong. Pilih file yang berisi data.';
    }
    return null;
  }

  /// Mengubah isi file menjadi daftar teks siap analisis.
  ///
  /// Encoding harus UTF-8; file dengan encoding tidak didukung akan ditolak
  /// dengan pesan yang jelas (RULES.md bagian 7).
  ParsedCsvFile parseBytes(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw const CsvFileException('File kosong. Pilih file yang berisi data.');
    }
    final String content;
    try {
      content = utf8.decode(bytes, allowMalformed: false);
    } on FormatException {
      throw const CsvFileException(
        'File tidak dapat dibaca. Pastikan file berencoding UTF-8, lalu coba '
        'lagi.',
      );
    }
    return parse(content);
  }

  /// Mengubah isi CSV menjadi daftar teks siap analisis.
  ///
  /// - BOM dan akhir baris dinormalkan agar parsing deterministik.
  /// - Baris tanpa kolom teks diperlakukan seperti pada versi web: nomor baris
  ///   tetap mengikuti posisi aslinya, tetapi baris tersebut tidak dikirim.
  ParsedCsvFile parse(String content) {
    var normalized = content;
    if (normalized.startsWith('\uFEFF')) {
      normalized = normalized.substring(1);
    }
    normalized = normalized.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    if (normalized.trim().isEmpty) {
      throw const CsvFileException('File kosong. Pilih file yang berisi data.');
    }

    final List<List<dynamic>> table;
    try {
      table = Csv(skipEmptyLines: true).decode(normalized);
    } on Exception {
      throw const CsvFileException(
        'File tidak dapat dibaca. Pastikan file CSV valid, lalu coba lagi.',
      );
    }

    const emptyDataMessage =
        'File tidak berisi baris data. Tambahkan minimal satu baris ulasan di '
        'bawah header.';
    if (table.isEmpty) {
      throw const CsvFileException(emptyDataMessage);
    }

    final contentIndex = _contentColumnIndex(table.first);
    if (contentIndex < 0) {
      throw CsvFileException(
        'Kolom ulasan tidak ditemukan. Pastikan file memiliki kolom '
        '"${ApiConfig.expectedColumn}" sebagai header, lalu coba lagi.',
      );
    }

    final validRows = <CsvTextRow>[];
    var totalRows = 0;
    for (var index = 1; index < table.length; index++) {
      final row = table[index];
      totalRows += 1;
      final raw = contentIndex < row.length ? row[contentIndex] : null;
      final text = (raw ?? '').toString().trim();
      if (text.isEmpty) continue;
      // Nomor baris memakai posisi baris pada file (header = baris 0),
      // sama seperti implementasi web.
      validRows.add(CsvTextRow(rowNumber: index, text: text));
    }

    if (totalRows == 0) {
      throw const CsvFileException(emptyDataMessage);
    }
    if (validRows.isEmpty) {
      throw const CsvFileException(
        'Semua baris pada kolom teks kosong. Pastikan kolom berisi teks '
        'ulasan.',
      );
    }

    return ParsedCsvFile(
      totalRows: totalRows,
      validRows: List<CsvTextRow>.unmodifiable(validRows),
    );
  }

  /// Mencari indeks kolom [ApiConfig.expectedColumn] tanpa membedakan huruf
  /// besar/kecil dan membuang BOM pada nama header.
  static int _contentColumnIndex(List<dynamic> header) {
    for (var index = 0; index < header.length; index++) {
      final name =
          header[index]
              ?.toString()
              .replaceFirst('\uFEFF', '')
              .trim()
              .toLowerCase() ??
          '';
      if (name == ApiConfig.expectedColumn) return index;
    }
    return -1;
  }
}
