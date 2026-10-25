# SteamSentiment Analyzer — Flutter Mobile App

Aplikasi mobile berbasis **Flutter** untuk mengklasifikasikan sentimen ulasan aplikasi Steam dari Google Play Store menjadi **Positif** atau **Negatif**. Aplikasi dirancang untuk layar ponsel dan menyediakan dua alur utama: analisis satu teks ulasan serta analisis massal melalui file CSV.

> **Status pengembangan:** Aplikasi ini merupakan sisi antarmuka mobile. Model machine learning diakses melalui backend/API FastAPI (`api/sesa_backend`). Kedua endpoint kontrak — `POST /predict` dan `POST /predict/batch` — sudah diselaraskan dengan backend tersebut. Selama server tidak berjalan atau model belum siap, aplikasi menampilkan status "Backend belum terhubung" beserta tombol **Coba lagi** dan tidak pernah menampilkan hasil simulasi sebagai prediksi model.

##  Fitur Utama

- **Satu composer untuk dua alur** — pengguna menulis ulasan atau melampirkan file `.csv` di tempat yang sama. Tidak ada tab/pemilihan mode. Enter mengirim (pada papan ketik fisik), Shift+Enter menyisipkan baris baru, dan tersedia tombol kirim.
- **Analisis satu ulasan** — label sentimen tampil di halaman yang sama, lengkap dengan kutipan ulasan dan confidence bila backend menyediakannya. Teks hanya dikosongkan setelah analisis berhasil; saat gagal teks tetap tersimpan.
- **Validasi file CSV** — periksa ekstensi `.csv`, ukuran maksimal 5 MB, encoding UTF-8, serta keberadaan kolom `content` (tanpa membedakan huruf besar/kecil, BOM dibuang). File baru dikirim setelah lolos validasi; baris dengan teks kosong tidak menjadi hasil dan dilaporkan backend sebagai baris dilewati.
- **Ringkasan hasil CSV** — nama file, jumlah total dan teranalisis, donut chart proporsi sentimen (digambar dengan `CustomPaint`, tanpa library chart), legenda persentase, serta catatan baris yang dilewati.
- **Tabel hasil per ulasan** — nomor, teks, dan label sentimen dengan pagination 10 baris per halaman. Gulir ke posisi teratas tabel dilakukan otomatis saat halaman berganti.
- **Ekspor hasil** — tombol **Unduh hasil** menyimpan **seluruh** baris hasil (bukan hanya halaman yang tampil) sebagai CSV ber-UTF-8 BOM dengan nama file yang sudah disanitasi.
- **Desain mobile-first** — identitas visual Steam: tema gelap, aksen biru `#66C0F4`, garis hairline, composer tetap di bawah layar, serta logo pulse yang digambar dari path SVG yang sama dengan versi web.
- **Penanganan status** — garis progres tipis saat menganalisis, counter karakter (maks 2000), pesan validasi di dekat komposer, status backend terhubung/belum di area hasil, dan tombol **Coba lagi** untuk mengulang tindakan yang gagal.

##  Teknologi

| Teknologi | Peran |
|---|---|
| Flutter (Material 3) | Framework antarmuka, tema gelap kustom |
| `http` | Komunikasi HTTP dengan backend API |
| `file_picker` | Memilih file CSV dan menyimpan hasil ekspor |
| `csv` | Membaca dan menulis data CSV |
| `CustomPaint` | Donut chart tanpa dependensi chart tambahan |
| `setState` + `ChangeNotifier` | State management sederhana tanpa framework tambahan |
| Python + FastAPI | Penyedia endpoint model machine learning (`api/sesa_backend`) |

##  Menjalankan Aplikasi

### Prasyarat

- Flutter SDK stabil (proyek ini dikembangkan dengan Flutter 3.47 / Dart 3.13).
- Android Studio atau VS Code dengan ekstensi Flutter dan Dart.
- Emulator Android atau perangkat Android fisik.
- Backend API yang berjalan jika ingin mendapatkan prediksi sungguhan.

### Langkah menjalankan

```bash
# 1. Unduh dependensi
flutter pub get

# 2. Jalankan backend SESA pada terminal terpisah
cd ../../api/sesa_backend
python -m uvicorn app.main:app --reload                  # Emulator
python -m uvicorn app.main:app --reload --host 0.0.0.0   # Perangkat fisik

# 3. Jalankan aplikasi (base URL default: http://127.0.0.1:8000)
flutter run

# 4. Atau tentukan alamat backend sendiri
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000   # Android Emulator
flutter run --dart-define=API_BASE_URL=http://192.168.1.5:8000 # Perangkat fisik
```

Base URL dikonfigurasi di satu tempat (`lib/services/api_config.dart`) melalui `--dart-define`, bukan ditulis berulang di banyak file. Nilai default `http://127.0.0.1:8000` cocok untuk backend pada komputer yang sama; Android Emulator harus memakai `http://10.0.2.2:8000` karena `localhost` pada perangkat menunjuk ke perangkat itu sendiri.

Sebelum menguji prediksi, pastikan backend sudah siap: `GET /ready` harus menjawab `{"model":"ready"}` (bila `not_ready`, aplikasi menampilkan status backend belum terhubung karena endpoint prediksi membalas 503).

### Perintah berguna

```bash
dart format .            # Format kode
flutter analyze          # Analisis statis
flutter test             # Menjalankan pengujian (68 pengujian)
flutter run              # Menjalankan aplikasi untuk pengembangan
flutter build apk --debug   # Build APK debug
```

##  Alur Penggunaan

### 1. Analisis satu ulasan

1. Halaman menampilkan judul utama "Analisis Sentimen Ulasan Steam" selama belum ada hasil.
2. Tulis atau tempel ulasan pada composer di bagian bawah layar.
3. Tekan **Enter** (papan ketik fisik) atau tombol panah kirim.
4. Aplikasi mengirim teks ke `POST /predict`; selama menunggu, garis progres tipis tampil di atas composer.
5. Hasil menampilkan label sentimen **Positif**/**Negatif** dan, bila disediakan backend, skor confidence. Input otomatis dikosongkan.
6. Jika gagal, teks tetap tersimpan dan area hasil menampilkan status + tombol **Coba lagi**.

### 2. Analisis massal melalui CSV

1. Ketuk ikon lampiran pada composer lalu pilih file `.csv` (petunjuk format tampil tepat di bawah composer).
2. File divalidasi (ekstensi, ukuran, encoding, kolom `content`); chip lampiran menampilkan nama file dan ukuran.
3. File baru dikirim setelah lolos validasi; baris dengan teks kosong tidak menjadi hasil dan dilaporkan backend sebagai baris dilewati.
4. Tekan tombol kirim untuk mengirim **file CSV asli** sebagai `multipart/form-data` ke `POST /predict/batch`.
5. Hasil menampilkan ringkasan (angka utama, donut chart, legenda persentase) lalu tabel detail per ulasan dengan pagination.
6. **Unduh hasil** menyimpan seluruh baris hasil sebagai CSV.
7. Melepas chip lampiran (ikon ×) memungkinkan pengguna kembali menulis ulasan tanpa menghapus hasil yang sedang tampil.

## 🔌 Integrasi Backend dan Model

Model yang dilatih di Google Colab **tidak dijalankan langsung di aplikasi Flutter**. Untuk model Python/scikit-learn, aplikasi memakai backend Python (FastAPI) yang memuat pipeline preprocessing dan model final.

```text
Flutter Mobile App
       |
       | HTTP/JSON
       v
Python API (FastAPI)
       |
       | preprocessing yang sama dengan eksperimen
       v
Pipeline + Model Machine Learning
       |
       v
Hasil prediksi sentimen → Flutter menampilkan hasil
```

### Kontrak API yang dipakai aplikasi

Kontrak berikut sudah diimplementasikan di `lib/services/sentiment_api_service.dart` dan disesuaikan dengan backend FastAPI pada `api/sesa_backend`.

| Method | Endpoint | Fungsi |
|---|---|---|
| `POST` | `/predict` | Memprediksi sentimen satu teks ulasan (JSON) |
| `POST` | `/predict/batch` | Menganalisis file CSV sebagai `multipart/form-data` (field `file`) |

`POST /predict`:

```json
// request
{ "text": "The game is fun and easy to use." }

// response
{ "text": "The game is fun and easy to use.", "label": "Positif" }
```

Field `confidence` bersifat opsional dan saat ini tidak dikirim backend. Bila tersedia, hanya nilai pada rentang 0..1 yang ditampilkan karena nilai di luar rentang itu tidak pasti.

`POST /predict/batch` — request berupa `multipart/form-data` dengan field `file` berisi file CSV asli (nama file dipakai backend untuk pemeriksaan tipe):

```json
// response
{
  "total": 250,
  "results": [ { "row": 2, "label": "Positif" } ],
  "skipped": [ { "row": 5, "reason": "baris tidak memiliki kolom teks yang valid" } ]
}
```

Respons batch tidak memuat teks ulasan, sehingga teks dan nomor baris diambil dari hasil parsing file di sisi aplikasi, sementara label hanya datang dari backend:

- Jumlah `results` sama dengan jumlah baris valid hasil parsing lokal → dipasangkan **berurutan** (backend mengirim hasil sesuai urutan input).
- Jumlahnya berbeda → respons dianggap melanggar kontrak dan ditampilkan sebagai pesan respons tidak valid dengan tombol **Coba lagi**, bukan diberi label tebakan.
- `skipped` dihitung sebagai baris dilewati, sehingga `Total = Dianalisis + baris dilewati`.

Label yang dikenali aplikasi: `Positif`/`Positive` dan `Negatif`/`Negative` (tanpa membedakan huruf besar/kecil). Label lain dianggap tidak sah dan memunculkan pesan respons tidak valid — bukan hasil tebakan.

### Hal penting dalam integrasi

- Pertahankan preprocessing yang sama dengan eksperimen Colab: pembersihan teks, tokenisasi/vektorisasi, dan urutan transformasi.
- Persentase pada ringkasan dihitung dari jumlah baris yang benar-benar diterima (`positiveCount + negativeCount`), sehingga angka ringkasan, legenda, dan donut selalu konsisten.
- Pesan galat backend dibaca dari field `detail`; status 503 (model belum siap) dan kegagalan koneksi ditampilkan sebagai status "backend belum terhubung" dengan tombol **Coba lagi**.
- Untuk perangkat fisik, jalankan uvicorn dengan `--host 0.0.0.0` dan arahkan `API_BASE_URL` ke IP LAN komputer pengembang.
- Gunakan HTTPS untuk layanan yang dipublikasikan. Hindari menyimpan kredensial atau API key di aplikasi mobile.

## 📁 Struktur Proyek

```text
lib/
├── main.dart                      # Titik masuk aplikasi
├── app.dart                       # MaterialApp + tema
├── theme/
│   └── app_theme.dart             # Token warna dan ThemeData
├── models/
│   ├── sentiment_label.dart       # Satu-satunya tempat pemetaan label
│   ├── single_analysis_result.dart
│   ├── csv_review_row.dart
│   └── csv_analysis_result.dart
├── services/
│   ├── api_config.dart            # Base URL, batas teks/ukuran, path endpoint
│   ├── sentiment_api_service.dart # Kontrak HTTP + pesan galat pengguna
│   ├── csv_file_service.dart      # Validasi dan parsing CSV
│   └── csv_export_service.dart    # Penulisan CSV hasil unduhan
├── controllers/
│   └── analysis_controller.dart   # State + aksi kedua alur analisis
├── pages/
│   └── analyze_page.dart          # Satu halaman: navbar, hasil, composer
└── widgets/
    ├── app_navbar.dart
    ├── pulse_logo.dart
    ├── hero_placeholder.dart
    ├── composer_card.dart
    ├── attachment_chip.dart
    ├── status_notice.dart
    ├── single_result_card.dart
    ├── csv_summary_card.dart
    ├── donut_chart.dart
    └── csv_result_table.dart

test/
├── models/model_parsing_test.dart
├── services/csv_file_service_test.dart
├── services/sentiment_api_service_test.dart
├── services/csv_export_service_test.dart
├── controllers/analysis_controller_test.dart
└── widget_test.dart               # Uji alur halaman (teks & CSV)
```

##  Panduan Antarmuka Mobile

- Pertahankan identitas visual terinspirasi Steam: tema gelap `#171A21`, permukaan `#1B2838`, aksen `#66C0F4`, dan garis hairline translusen. Token warna terpusat di `lib/theme/app_theme.dart` dan selaras dengan `frontend/src/styles/global.css`.
- Utamakan satu kolom pada layar ponsel; lebar konten dibatasi 760 px agar tetap nyaman di layar lebar.
- Jangan mengandalkan warna sebagai satu-satunya indikator sentimen; label teks selalu menyertainya.
- Pesan validasi tampil dekat kontrol yang bermasalah; status galat tampil di area hasil.
- Animasi dibatasi transisi 200 ms dan otomatis dinolkan ketika sistem meminta reduksi animasi.
- Jangan menyamarkan hasil simulasi sebagai hasil prediksi model.

##  Pengujian

Pengujian yang tersedia (`flutter test`, 68 pengujian):

- Parsing model: label sah/tidak sah, confidence di luar rentang, ringkasan dihitung dari data yang diterima, dan pembagian nol.
- Pembacaan CSV: koma dan newline di dalam kutipan, BOM, header huruf campuran, nomor baris yang dipertahankan saat ada baris dilewati, file tanpa kolom `content`, file kosong, encoding tidak didukung, dan file satu kolom.
- Layanan API: kontrak request/response kedua endpoint (JSON dan multipart), pesan `detail` dari backend, status 404/500/503, server tidak terjangkau, respons bukan JSON, dan label tidak dikenali — semuanya dengan `MockClient`, tanpa jaringan.
- Pemodelan batch: pemetaan hasil backend ke parsing lokal secara berurutan, baris yang dilewati, dan respons tanpa label sah.
- Controller: teks tidak valid tidak memanggil API, teks tersimpan saat gagal dan dikosongkan saat sukses, lampiran CSV valid/ditolak, dan retry yang mengarah ke tindakan yang benar.
- Halaman: empty state, counter karakter, validasi, hasil teks tunggal, status backend belum terhubung (tanpa hasil palsu), serta alur CSV lengkap dengan pagination.
- Ketahanan layout: navbar, ringkasan, tabel, dan pagination tetap utuh (tanpa overflow) pada layar 360px berskala font 2x.

Belum teruji otomatis: interaksi nyata pemilih file dan dialog simpan (platform channel), serta tampilan pada perangkat fisik.

##  Roadmap

- [x] Menyelesaikan antarmuka mobile Flutter yang mengikuti identitas visual versi web.
- [x] Menetapkan kontrak request/response antara Flutter dan backend.
- [x] Menghubungkan alur satu ulasan dan alur CSV ke lapisan service.
- [x] Menyesuaikan kontrak Flutter dengan backend `api/sesa_backend` (field `label`, `POST /predict/batch` multipart, dan pemetaan nomor baris).
- [x] Menambahkan ringkasan statistik, donut chart, tabel, pagination, dan ekspor hasil.
- [ ] Memverifikasi kedua endpoint terhadap backend yang sebenarnya di emulator dan perangkat fisik.
- [ ] Menguji aplikasi pada emulator dan perangkat Android fisik.
- [ ] Menyiapkan build rilis dan dokumentasi instalasi.

## 📄 Catatan

Proyek ini ditujukan untuk demonstrasi dan pembelajaran klasifikasi sentimen ulasan Steam. Hasil analisis yang ditampilkan harus berasal dari model machine learning melalui backend yang terhubung. Ketika backend belum berjalan atau model belum siap, aplikasi menampilkan status "Backend belum terhubung" dan tidak memunculkan label sentimen apa pun.

Versi Flutter ini adalah aplikasi mobile terpisah dari antarmuka web di [Nepft/SESA](https://github.com/Nepft/SESA). Keduanya dapat memakai backend dan model yang sama selama kontrak API konsisten.
