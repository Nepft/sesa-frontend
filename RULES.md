# RULES.md — Aturan Pengembangan SESA Flutter

Dokumen ini menetapkan aturan praktis untuk pengembangan aplikasi mobile SESA menggunakan Flutter. Aturan ini melengkapi `AGENT.md`.

## 1. Bahasa dan Gaya Kode

- Gunakan Dart dan ikuti konvensi resmi Flutter.
- Jalankan `dart format` untuk memformat kode.
- Gunakan nama `UpperCamelCase` untuk class dan enum, serta `lowerCamelCase` untuk variabel, fungsi, dan parameter.
- Gunakan nama file Dart `snake_case.dart`.
- Hindari nama yang terlalu umum seperti `data`, `item`, atau `helper` jika nama yang lebih spesifik dapat menjelaskan maksudnya.
- Utamakan kode yang mudah dibaca daripada abstraksi yang berlebihan.
- Tambahkan komentar untuk menjelaskan alasan atau perilaku yang tidak jelas, bukan mengulang isi kode.

## 2. Aturan Perubahan Kode

- Periksa implementasi yang ada sebelum menulis ulang komponen.
- Buat perubahan sekecil mungkin dan tetap fokus pada permintaan.
- Gunakan kembali widget, model, service, dan tema yang sudah tersedia jika sesuai.
- Jangan mengganti seluruh struktur proyek hanya demi preferensi pribadi.
- Jangan menambahkan package baru jika fitur dapat diselesaikan dengan dependensi yang sudah ada atau API Flutter standar.
- Jika menambahkan package, pastikan paket tersebut relevan, kompatibel, dan benar-benar digunakan.
- Jangan meninggalkan import, fungsi, variabel, atau dependency yang tidak digunakan.
- Jangan menghapus perilaku yang sudah ada tanpa alasan dan penjelasan.

## 3. UI dan Responsivitas

- Rancang untuk layar ponsel terlebih dahulu, lalu pastikan layout tetap berfungsi pada ukuran layar berbeda.
- Hindari ukuran lebar/tinggi tetap yang menyebabkan overflow pada layar kecil.
- Gunakan `SafeArea`, scrolling, dan penyesuaian keyboard jika diperlukan.
- Pastikan input dan tombol tetap dapat digunakan ketika keyboard terbuka.
- Sediakan indikator loading dan cegah pengiriman permintaan berulang yang tidak disengaja.
- Tampilkan pesan validasi dan error yang spesifik, singkat, serta mudah dipahami.
- Jangan menggunakan warna saja untuk membedakan sentimen; sertakan label teks atau ikon yang sesuai.
- Pastikan ukuran teks dan kontras mendukung keterbacaan.
- Pertahankan identitas visual yang merujuk pada versi web SESA dan Steam, kecuali ada arahan desain baru.

## 4. State dan Struktur

- Hindari menaruh seluruh logika aplikasi di satu widget atau satu file besar.
- Pisahkan komunikasi jaringan dari widget UI.
- Gunakan pola state management yang telah dipakai proyek. Jika belum ditentukan, pilih solusi sederhana yang sesuai kebutuhan dan konsisten.
- Jangan memperkenalkan beberapa state-management framework sekaligus.
- Kelola lifecycle dengan benar; hindari pembaruan state setelah widget tidak lagi terpasang.
- Hindari pemanggilan API berulang akibat rebuild widget.
- Gunakan model bertipe untuk data penting jika lebih aman dan jelas daripada `dynamic` atau `Map` yang tersebar di seluruh aplikasi.

## 5. API dan Model

- Kontrak API yang sudah diverifikasi menjadi sumber kebenaran.
- Jangan mengarang endpoint, field JSON, nilai confidence, atau label hasil.
- Simpan base URL dalam konfigurasi yang mudah diganti; jangan menulis URL berulang di banyak file.
- Tangani status HTTP, timeout, kegagalan koneksi, JSON yang tidak valid, dan respons yang tidak sesuai skema.
- Jangan mengirim teks kosong atau file yang gagal divalidasi ke backend.
- Jangan menampilkan respons error sebagai hasil analisis yang sukses.
- Jangan menganggap `localhost` pada perangkat Android menunjuk ke komputer pengembang. Untuk Android Emulator, alamat host biasanya `10.0.2.2`; untuk perangkat fisik gunakan alamat server yang dapat dijangkau perangkat.
- Gunakan HTTPS pada lingkungan produksi.
- Jangan menyimpan secret atau kredensial privat di aplikasi mobile.

## 6. Aturan Analisis Sentimen

- Hasil yang ditampilkan harus berasal dari model yang benar-benar terhubung.
- Jangan membuat hasil prediksi atau confidence untuk mengisi tampilan.
- Pastikan preprocessing inferensi konsisten dengan preprocessing saat eksperimen.
- Jangan mengganti model, label kelas, atau aturan pemrosesan tanpa persetujuan dan alasan yang terdokumentasi.
- Jika backend belum tersedia, tampilkan status belum terhubung atau error yang sesuai.
- Jangan menyebut analisis sebagai real-time atau akurat tanpa dasar implementasi dan evaluasi.

## 7. Aturan File CSV

- Validasi file yang dipilih, ekstensi, ukuran, dan struktur kolom yang diperlukan.
- Nama kolom teks harus mengikuti kontrak backend/dataset yang sebenarnya; jangan mengasumsikan nama kolom tanpa memeriksa sumber data.
- Tangani file kosong, header tidak ada, baris kosong, encoding yang tidak didukung, serta CSV yang tidak valid.
- Untuk dataset besar, hindari memuat atau merender semua baris sekaligus jika dapat menyebabkan penggunaan memori tinggi.
- Ringkasan jumlah dan persentase sentimen harus dihitung dari data hasil yang benar-benar diterima.
- Ekspor harus menyertakan hasil sesuai kebutuhan, bukan hanya baris yang sedang terlihat di layar.
- Jangan menimpa file pengguna tanpa tindakan yang jelas dan disengaja.

## 8. Error, Logging, dan Privasi

- Error yang dilihat pengguna harus membantu mereka memahami langkah berikutnya.
- Detail teknis boleh dicatat untuk debugging, tetapi jangan menampilkan stack trace mentah di UI produksi.
- Jangan mencatat teks ulasan atau data pengguna secara berlebihan jika tidak dibutuhkan.
- Jangan menyimpan dataset atau hasil analisis secara permanen tanpa kebutuhan dan persetujuan yang jelas.
- Jangan memasukkan file `.env`, secret, token, atau data sensitif ke version control.
- Tambahkan file konfigurasi lokal ke `.gitignore` jika berisi nilai privat.

## 9. Pengujian dan Validasi

Setelah perubahan yang relevan, jalankan:

```bash
dart format .
flutter analyze
flutter test
```

Jika proyek besar, pemformatan dapat dibatasi pada file yang berubah, misalnya:

```bash
dart format lib/path/to/changed_file.dart
```

- Tambahkan pengujian untuk parsing model, validasi input, dan transformasi data yang penting.
- Uji state loading, sukses, empty, dan error bila relevan.
- Jangan mengklaim tes berhasil jika perintah belum dijalankan atau gagal.
- Catat keterbatasan pengujian jika backend atau perangkat tidak tersedia.

## 10. Git dan Dokumentasi

- Gunakan commit yang menjelaskan perubahan secara spesifik.
- Jangan memasukkan hasil build, cache, file sementara, secret, atau dataset besar ke commit tanpa alasan.
- Perbarui `README.md` jika setup, fitur, atau alur integrasi berubah.
- Dokumentasikan endpoint dan contoh request/response hanya setelah dikonfirmasi.
- Bedakan dengan jelas antara fitur yang sudah diterapkan dan rencana pengembangan.

## 11. Checklist Sebelum Menyelesaikan Tugas

- [ ] Perubahan sesuai permintaan dan tidak merusak fitur yang sudah ada.
- [ ] UI berfungsi pada layar ponsel dan tidak mengalami overflow yang diketahui.
- [ ] Loading, empty, dan error state ditangani jika relevan.
- [ ] Tidak ada hasil model palsu atau data contoh yang disamarkan sebagai hasil nyata.
- [ ] API dan parsing mengikuti kontrak yang diverifikasi.
- [ ] Kode diformat dan dianalisis.
- [ ] Pengujian relevan dijalankan atau kendalanya dijelaskan.
- [ ] Dokumentasi diperbarui jika diperlukan.
