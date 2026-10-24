# AGENT.md — SESA Flutter

## Peran Agen

Agen coding yang bekerja pada proyek ini membantu mengembangkan aplikasi mobile Flutter untuk **SESA / SteamSentiment Analyzer**. Aplikasi digunakan untuk menjalankan analisis sentimen ulasan aplikasi Steam, baik satu teks maupun kumpulan ulasan dari file CSV.

Agen harus memprioritaskan implementasi yang benar-benar berjalan, struktur kode yang mudah dipelihara, pengalaman mobile yang baik, dan integrasi yang konsisten dengan model machine learning yang telah diuji di Google Colab.

## Konteks Proyek

- **Platform:** Flutter untuk aplikasi mobile, dengan fokus utama Android.
- **Bahasa:** Dart.
- **Produk:** antarmuka mobile untuk analisis sentimen ulasan Steam.
- **Alur analisis:** satu teks ulasan dan unggah file CSV.
- **Model:** model machine learning telah dikembangkan/diuji di Google Colab.
- **Integrasi yang disarankan:** Flutter berkomunikasi dengan backend Python melalui HTTP API.
- **Referensi visual:** versi web di repository `https://github.com/Nepft/SESA`; pertahankan identitas visual yang sesuai dengan Steam sambil mengadaptasi tata letak untuk ponsel.

Jangan mengasumsikan backend, endpoint, model, nama kolom CSV, atau struktur folder tertentu sudah tersedia sebelum memeriksa repository.

## Tanggung Jawab Utama

1. Memeriksa struktur dan kode yang sudah ada sebelum membuat atau mengubah file.
2. Mengembangkan antarmuka yang mobile-first, responsif, konsisten, dan mudah digunakan.
3. Memisahkan UI, model data, logika state, dan komunikasi API sesuai skala proyek.
4. Mengimplementasikan analisis satu ulasan dan analisis CSV sesuai kontrak backend yang sebenarnya.
5. Menampilkan hasil prediksi yang benar-benar berasal dari model; jangan mengganti kegagalan API dengan prediksi palsu.
6. Menangani loading, data kosong, validasi input, kesalahan jaringan, timeout, dan respons server yang tidak valid.
7. Menulis atau memperbarui pengujian yang relevan untuk perubahan penting.
8. Menjaga dokumentasi, instruksi setup, dan dependensi tetap sesuai dengan implementasi.

## Prosedur Kerja

Sebelum mengubah kode:

1. Periksa `README.md`, `RULES.md`, `pubspec.yaml`, struktur `lib/`, dan implementasi terkait.
2. Identifikasi apakah fitur atau komponen serupa sudah tersedia.
3. Periksa kontrak API dan contoh respons yang benar-benar digunakan. Jika belum ada, tandai sebagai kebutuhan atau usulkan kontrak—jangan berpura-pura endpoint sudah tersedia.
4. Tentukan perubahan terkecil yang menyelesaikan kebutuhan tanpa merombak bagian yang tidak terkait.
5. Jika detail penting tidak diketahui, ajukan pertanyaan singkat atau dokumentasikan asumsi yang diperlukan.

Setelah mengubah kode:

1. Jalankan `dart format` pada file Dart yang berubah.
2. Jalankan `flutter analyze`.
3. Jalankan pengujian relevan dengan `flutter test`.
4. Jika perintah tidak dapat dijalankan, jelaskan penyebabnya dan jangan mengklaim pemeriksaan berhasil.
5. Ringkas file yang diubah, perilaku yang ditambahkan, hasil pemeriksaan, dan pekerjaan yang masih diperlukan.

## Panduan Arsitektur

Utamakan struktur sederhana. Gunakan pola yang sudah dipakai proyek jika konsisten; jangan menambahkan arsitektur atau state-management package baru tanpa alasan.

Contoh struktur yang dapat digunakan jika sesuai:

```text
lib/
├── main.dart
├── app.dart
├── models/
├── pages/
├── widgets/
├── services/
├── controllers/    # atau state management yang sudah dipilih proyek
└── theme/
```

- **Pages:** menyusun layar dan alur navigasi.
- **Widgets:** komponen UI yang dapat digunakan ulang.
- **Models:** model request/response dan data hasil analisis.
- **Services:** komunikasi API, parsing file, dan operasi eksternal.
- **Controllers/state:** mengelola state dan aksi pengguna.
- **Theme:** warna, tipografi, tema, dan gaya komponen.

Jangan membuat file atau lapisan abstraksi hanya untuk mengikuti contoh struktur jika proyek belum membutuhkannya.

## Integrasi Machine Learning

- Model yang dibuat di Google Colab harus diakses dengan cara yang sesuai format dan lingkungan inferensinya.
- Untuk model Python/scikit-learn, gunakan backend Python jika model belum dikonversi ke format inferensi on-device yang didukung.
- Pastikan preprocessing saat inferensi sama dengan pipeline eksperimen.
- Ikuti label, nama field, skema request/response, dan format confidence yang ditentukan backend.
- Jangan membuat nilai prediksi, confidence, statistik, atau hasil CSV palsu.
- Jika API belum tersedia, buat lapisan service yang jelas dan dokumentasikan kontrak yang dibutuhkan. UI boleh memiliki empty/error state, tetapi jangan menyajikan data demo sebagai hasil nyata.
- Jangan menaruh secret, token privat, atau API key rahasia di kode aplikasi mobile.

## Panduan UI/UX

- Gunakan pendekatan **mobile-first**; jangan sekadar mengecilkan layout desktop.
- Pertahankan identitas visual Steam dari versi web sebagai referensi, tetapi optimalkan hierarki, navigasi, dan kepadatan konten untuk layar kecil.
- Pastikan teks terbaca, kontras memadai, area sentuh nyaman, dan keyboard tidak menutupi input.
- Sediakan state loading, success, empty, dan error.
- Untuk hasil CSV, tampilkan ringkasan sebelum daftar detail; hindari memuat seluruh dataset besar ke widget sekaligus.
- Jangan menambahkan animasi berat atau dependensi visual tanpa kebutuhan nyata.
- Ikuti komponen dan pola desain yang telah digunakan proyek sebelum menciptakan pola baru.

## Batasan

- Jangan mengubah hasil eksperimen, label kelas, atau metode preprocessing tanpa instruksi dan alasan teknis yang jelas.
- Jangan mengklaim model Flutter berjalan lokal jika prediksi sebenarnya berasal dari API.
- Jangan menambahkan autentikasi, database, histori pengguna, atau fitur lain yang tidak diminta.
- Jangan menghapus file atau melakukan perubahan destruktif tanpa memeriksa dampaknya.
- Jangan memasukkan kredensial, data pribadi, atau file dataset sensitif ke repository.
- Jangan menganggap contoh URL API, nama kolom, maupun JSON di dokumentasi sebagai kontrak final tanpa verifikasi.

## Definisi Selesai

Sebuah perubahan dianggap selesai jika:

- Kebutuhan yang diminta telah diimplementasikan sesuai konteks proyek.
- UI memiliki state yang relevan dan tidak menyesatkan pengguna.
- Tidak ada error analisis Dart yang diperkenalkan oleh perubahan.
- Pengujian relevan berhasil, atau kendala pengujian dijelaskan dengan jujur.
- Dokumentasi yang terdampak diperbarui.
