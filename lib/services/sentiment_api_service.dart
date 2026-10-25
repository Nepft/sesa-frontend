import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/csv_analysis_result.dart';
import '../models/single_analysis_result.dart';
import 'api_config.dart';
import 'csv_file_service.dart';

/// Galat yang aman ditampilkan ke pengguna: pesan sudah berbahasa Indonesia,
/// menjelaskan langkah berikutnya, dan tanpa stack trace (RULES.md bagian 8).
class SentimentApiException implements Exception {
  const SentimentApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Server tidak dapat dijangkau atau endpoint yang dibutuhkan belum tersedia.
class BackendUnavailableException extends SentimentApiException {
  const BackendUnavailableException(super.message);
}

/// Respons server tidak sesuai kontrak (bukan JSON, skema tak dikenali).
class InvalidResponseException extends SentimentApiException {
  const InvalidResponseException(super.message);
}

/// Lapisan batas aplikasi dengan backend prediksi SESA.
///
/// Kontrak yang dipakai (sudah diverifikasi terhadap backend FastAPI):
///
/// - `POST /predict`: satu teks ulasan.
/// - `POST /predict/batch`: file CSV sebagai multipart.
///
/// Kegagalan koneksi, timeout, status HTTP di luar 2xx, dan respons yang tidak
/// sesuai skema semuanya dipilihkan pesan galat yang dapat ditindaklanjuti
/// pengguna; UI wajib menampilkannya sebagai status, bukan sebagai hasil.
class SentimentApiService {
  SentimentApiService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _client;

  /// Alamat backend. Bisa dioverride lewat `--dart-define=API_BASE_URL=...`.
  final String baseUrl;

  static const String backendUnavailableMessage =
      'Backend belum terhubung. Prediksi belum tersedia. Jalankan server API '
      'lalu coba lagi.';

  /// Mengirim satu teks ulasan ke `POST /predict`.
  ///
  /// Kontrak request/response:
  ///
  /// ```json
  /// // request
  /// { "text": "The game is fun." }
  /// // response
  /// { "text": "The game is fun.", "label": "Positif" }
  /// ```
  ///
  /// Field `confidence` bersifat opsional; bila backend menyertakannya pada
  /// rentang 0..1, nilai itu ikut ditampilkan.
  Future<SingleAnalysisResult> predictText(String text) async {
    final response = await _post(ApiConfig.predictPath, {'text': text});
    _ensureSuccess(response.statusCode, response.body);
    final json = _decodeObject(response.body);
    try {
      return SingleAnalysisResult.fromJson(json, submittedText: text);
    } on FormatException catch (error) {
      throw InvalidResponseException(error.message);
    }
  }

  /// Mengirim file CSV ke `POST /predict/batch` sebagai `multipart/form-data`
  /// dengan nama berkas `file`, sesuai parameter `UploadFile` backend.
  ///
  /// ```json
  /// // response
  /// {
  ///   "total": 250,
  ///   "results": [ { "row": 2, "label": "Positif" } ],
  ///   "skipped": [ { "row": 5, "reason": "baris kosong" } ]
  /// }
  /// ```
  ///
  /// [parsed] adalah hasil validasi/parsing file yang sama di sisi aplikasi.
  /// Parsing tetap dilakukan lebih dulu agar struktur kolom tervalidasi sebelum
  /// file dikirim, dan agar teks tiap baris tetap tersedia untuk tabel serta
  /// ekspor (respons backend tidak memuat teks).
  Future<CsvAnalysisResult> analyzeCsv({
    required String fileName,
    required Uint8List bytes,
    required ParsedCsvFile parsed,
  }) async {
    final request =
        http.MultipartRequest(
            'POST',
            Uri.parse('$baseUrl${ApiConfig.batchPath}'),
          )
          ..files.add(
            http.MultipartFile.fromBytes('file', bytes, filename: fileName),
          );

    final body = await _sendMultipart(request);
    final json = _decodeObject(body);
    try {
      return CsvAnalysisResult.fromBatchResponse(
        json,
        fileName: fileName,
        parsed: parsed,
      );
    } on FormatException catch (error) {
      throw InvalidResponseException(error.message);
    }
  }

  Future<http.Response> _post(String path, Map<String, dynamic> body) async {
    return _transport(
      ApiConfig.timeout,
      () => _client.post(
        Uri.parse('$baseUrl$path'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ),
    );
  }

  Future<String> _sendMultipart(http.BaseRequest request) async {
    final streamed = await _transport(
      ApiConfig.batchTimeout,
      () => _client.send(request),
    );
    final String body;
    try {
      body = await streamed.stream.bytesToString();
    } on FormatException {
      throw const InvalidResponseException(
        'Respons server bukan teks yang valid.',
      );
    } on http.ClientException {
      throw const BackendUnavailableException(backendUnavailableMessage);
    }
    _ensureSuccess(streamed.statusCode, body);
    return body;
  }

  /// Menjalankan permintaan sambil menangani kegagalan transport yang umum
  /// menjadi pesan galat yang dapat ditampilkan (RULES.md bagian 8).
  Future<T> _transport<T>(Duration timeout, Future<T> Function() send) async {
    try {
      return await send().timeout(timeout);
    } on TimeoutException {
      throw const SentimentApiException(
        'Server tidak merespons (waktu tunggu habis). Periksa koneksi lalu '
        'coba lagi.',
      );
    } on SocketException {
      throw const BackendUnavailableException(backendUnavailableMessage);
    } on http.ClientException {
      // package:http membungkus kegagalan koneksi seperti server tak berjalan.
      throw const BackendUnavailableException(backendUnavailableMessage);
    }
  }

  /// Menukar status HTTP non-2xx menjadi galat yang dapat ditampilkan.
  ///
  /// Pesan `detail` dari backend dipakai lebih dulu karena sudah disiapkan
  /// sebagai pesan aman untuk klien; bila tidak ada, dipakai pesan generik
  /// yang menyebut status HTTP-nya.
  void _ensureSuccess(int statusCode, String body) {
    if (statusCode >= 200 && statusCode < 300) return;
    if (statusCode == HttpStatus.notFound) {
      throw const BackendUnavailableException(
        'Endpoint prediksi belum tersedia di server. Hubungkan backend '
        'terlebih dahulu.',
      );
    }
    final detail = _errorDetail(body);
    if (statusCode == HttpStatus.serviceUnavailable) {
      // 503 berarti model belum siap / backend belum siap dilayani.
      throw BackendUnavailableException(detail ?? backendUnavailableMessage);
    }
    throw SentimentApiException(
      detail ?? 'Server mengembalikan galat HTTP $statusCode. Coba lagi.',
    );
  }

  /// Membaca field `detail` pada respons galat JSON milik backend.
  static String? _errorDetail(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];
        if (detail is String && detail.trim().isNotEmpty) {
          return detail.trim();
        }
      }
    } on FormatException {
      // Bukan JSON; biarkan pemanggil memakai pesan generik.
    }
    return null;
  }

  Map<String, dynamic> _decodeObject(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException {
      // Jatuh ke pesan di bawah agar pengguna tetap mendapat penjelasan jelas.
    }
    throw const InvalidResponseException(
      'Respons server bukan objek JSON yang valid.',
    );
  }
}
