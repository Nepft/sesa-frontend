/// Konfigurasi komunikasi API.
///
/// Base URL diatur lewat `--dart-define` agar tidak ditulis berulang di
/// banyak file:
///
/// ```bash
/// # Android Emulator (default): mengakses host komputer
/// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
///
/// # Perangkat fisik: gunakan alamat IP LAN komputer pengembang
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.5:8000
/// ```
abstract final class ApiConfig {
  /// Default memakai alamat host khusus Android Emulator.
  /// `localhost` pada perangkat menunjuk ke perangkat itu sendiri, bukan
  /// komputer pengembang (RULES.md bagian 5).
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static const Duration timeout = Duration(seconds: 20);

  /// Batas tunggu unggahan CSV: file 5 MB + inferensi batch butuh waktu lebih
  /// lama daripada prediksi satu teks.
  static const Duration batchTimeout = Duration(seconds: 300);

  /// Batas panjang teks ulasan, konsisten dengan versi web.
  static const int maxTextLength = 2000;

  /// Batas ukuran file CSV (5 MB).
  static const int maxFileSizeBytes = 5 * 1024 * 1024;

  /// Nama kolom teks pada file CSV mengikuti kontrak dataset yang dipakai
  /// versi web; jangan diubah tanpa konfirmasi dari backend/dataset.
  static const String expectedColumn = 'content';

  static const String predictPath = '/predict';

  /// Endpoint batch menerima file CSV sebagai multipart, bukan JSON.
  static const String batchPath = '/predict/batch';
}
