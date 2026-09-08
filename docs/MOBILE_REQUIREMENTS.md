# 📱 Mobile App: Frontend UI/UX Requirements (Detailed)

Dokumen ini adalah *Software Requirements Specification* (SRS) tingkat lanjut untuk tim Mobile Developer (Flutter/React Native/Kotlin/Swift) yang akan membangun aplikasi Android untuk Endog Racing. 

Dokumen ini memetakan endpoint API ke dalam komponen layar (*screens*), tombol aksi, *local storage/state*, serta aturan validasi *client-side* untuk Role Anak Kandang dan Role Sales.

---

## 1. Modul Autentikasi & Verifikasi Kehadiran

### A. Layar Login & Pemilihan Role (`/login`)
- **Tujuan:** Pintu masuk aplikasi dengan pemisahan akses yang tegas.
- **Komponen UI:**
  - **Tabs/Toggle:** `[Login Kandang]` dan `[Login Sales]`.
  - **Input:** Username (Text), Password (Password).
  - **Tombol Aksi Utama:** `[Masuk]`.
- **Detail Logic:** 
  - Jika Tab Kandang dipilih, aplikasi *hit* `POST /api/login/kandang`. Jika Tab Sales dipilih, hit `POST /api/login/sales`.
  - Simpan Bearer Token di *Secure Storage*.

### B. Verifikasi Kehadiran & Geofencing (Khusus Anak Kandang)
- **Tujuan:** Memastikan Anak Kandang benar-benar berada di lokasi fisik kandang sebelum bisa bekerja.
- **Komponen UI:**
  - **Scanner Kamera:** Membuka kamera untuk men-scan Barcode QR yang tertempel di dinding Kandang.
- **Spesifikasi Flow & Validasi Frontend:**
  1. Aplikasi harus meminta *Permission Location* (GPS) secara presisi (*High Accuracy*).
  2. Saat tombol `[Scan QR Kandang]` ditekan, aplikasi membaca QR (berisi `kandang_code`).
  3. Aplikasi mengambil Latitude & Longitude dari GPS *Device*.
  4. Aplikasi mengirim Payload `{kandang_code, latitude, longitude}` ke `POST /api/kandang/verify-barcode`.
  5. Jika lolos, simpan `kandang_code` di *Local State* / *Session* sebagai referensi wajib untuk seluruh transaksi harian Anak Kandang tersebut.
- **Endpoint:** `POST /api/kandang/verify-barcode`

---

## 2. Modul Operasional Anak Kandang (Role: Kandang)

*(Semua endpoint di bawah ini mewajibkan pengiriman `kandang_code` dari hasil verifikasi di Modul 1).*

### A. Beranda Kandang / Dashboard (`/kandang/dashboard`)
- **Tujuan:** Halaman utama anak kandang menampilkan *to-do list* dan status ayam.
- **Komponen UI:**
  - **Widget:** Total Populasi Ayam Hidup.
  - **Grid Menu:** Ikon besar untuk: `[Turun Pakan]`, `[Panen Telur]`, `[Lapor Mati]`, `[Checklist Kebersihan]`.
- **Endpoint:** `GET /api/kandang/dashboard`

### B. Form Permintaan Turun Pakan (`/kandang/pakan`)
- **Tujuan:** Meminta pakan dari gudang pusat ke kandang (untuk divalidasi admin).
- **Komponen UI:**
  - Teks Informasi (Read-only): Menampilkan nama kandang.
  - **Dropdown Produk:** Menampilkan daftar Pakan (diambil dari API Form).
  - **Input Angka:** `Qty (Zak)`.
  - **Keterangan:** Textarea opsional.
  - **Tombol Aksi:** `[Minta Pakan]`.
- **Validasi Frontend:**
  - Tombol submit mati (*disabled*) selama loading untuk mencegah *double-request*.
  - Qty minimal = 1.
- **Endpoint:** `GET /api/pemakaian-pakan/form` (untuk dropdown), `POST /api/pemakaian-pakan`

### C. Form Panen Telur (`/kandang/telur`)
- **Tujuan:** Menyetor hasil telur harian langsung ke gudang pusat.
- **Komponen UI:**
  - **Dropdown Produk:** Jenis Telur (diambil dari form).
  - **Input Angka Kompleks:** Sediakan dua kolom sejajar: `[Qty Kilogram (Kg)]` dan `[Qty Butir]`.
  - **Kondisi Telur:** Radio Button `[Normal]` atau `[Rusak]`.
- **Validasi Frontend:**
  - Salah satu antara Kg atau Butir harus terisi `> 0`.
  - Jika Radio Button = Rusak, Frontend wajib memunculkan peringatan pop-up: *"Telur rusak tidak bisa dijual, lanjutkan?"*
- **Endpoint:** `GET /api/produksi-telur/form`, `POST /api/produksi-telur`

### D. Laporan Kematian / Afkir (`/kandang/kematian`)
- **Tujuan:** Mengurangi populasi kandang akibat ayam mati atau sakit.
- **Komponen UI:**
  - **Input Qty:** Jumlah ayam (Ekor).
  - **Kategori:** Radio Button `[Kematian (Mortalitas)]` atau `[Afkir (Culling)]`.
  - **Penyebab:** Dropdown Penyakit (ditarik dari API form).
  - **Catatan Gejala:** Textarea.
- **Validasi Frontend:**
  - Qty mati tidak boleh melebihi sisa populasi hidup yang ditampilkan di dashboard.
- **Endpoint:** `GET /api/populasi/form`, `POST /api/populasi`

### E. Checklist Kebersihan (`/kandang/checklist`)
- **Tujuan:** Bukti Anak Kandang sudah membersihkan area kerjanya.
- **Komponen UI:**
  - List baris berisi Checkbox (misal: "Sapu Lorong", "Cek Nipple Air", dll). Data ini dinamis ditarik dari API.
  - **Tombol Aksi Utama:** `[Kirim Laporan Harian]`.
- **Validasi Frontend:**
  - Munculkan pesan sukses dengan ikon ceklis besar (Lottie Animation) ketika laporan berhasil dikirim.
- **Endpoint:** `GET /api/checklist`, `POST /api/checklist/submit`

---

## 3. Modul Perdagangan (Role: Sales)

### A. Beranda Sales
- **Tujuan:** Halaman awal Sales untuk melihat ringkasan tugas.
- **Komponen UI:**
  - Tombol aksi raksasa: `[Buat Penjualan]`, `[Top Up Deposit]`, `[Cek Saldo Agen]`.

### B. Transaksi Penjualan Telur (`/sales/penjualan`)
- **Tujuan:** Mencatat penjualan ke Customer/Agen dan memotong stok gudang.
- **Komponen UI (Wizard / Multi-step):**
  - **Step 1: Pilih Customer.** Dropdown Searchable Customer (diambil dari API Form).
  - **Step 2: Metode Pembayaran.** Pilihan: `[Tunai]`, `[Deposit]`, `[Tempo]`.
    - *Jika "Deposit" dipilih:* Frontend secara diam-diam memanggil `GET /api/deposit/{code}/saldo`. Tampilkan saldo *Current Deposit* pelanggan.
  - **Step 3: Detail Barang.** 
    - Pilih Telur (Stok Gudang Sentral & Harga HPP akan dikembalikan oleh API).
    - Input `Qty (Kg)`.
    - Input `Harga Jual (Rp/Kg)`. Default terisi dari HPP/Harga Dasar, tapi *Editable*.
  - **Subtotal Live Calculation:** `Qty * Harga Jual`.
- **Validasi Frontend (PENTING - Proteksi Harga Sentral):**
  - Jika Harga Jual yang di-input < Harga Dasar (HPP), ubah warna input jadi MERAH, berikan pesan *"Harga terlalu rendah!"*, dan disable tombol `[Submit]`.
  - Jika Metode Pembayaran = Deposit, dan Grand Total tagihan > Saldo Deposit, disable tombol `[Submit]` dan beri tahu *"Saldo deposit agen tidak cukup"*.
- **Endpoint:** `GET /api/penjualan/form`, `POST /api/penjualan`

### C. Top Up & Cek Deposit Kustomer (`/sales/deposit`)
- **Tujuan:** Menerima titipan uang dari agen sebagai deposit untuk pembelian telur ke depan.
- **Komponen UI:**
  - **Dropdown:** Pilih Customer.
  - **Detail View:** Saat customer dipilih, tampilkan dua kotak informasi: `[Total Sisa Deposit]` dan list `[Riwayat Potongan/Tambahan]`.
  - **Tombol Aksi:** `[+ Terima Setoran Deposit]`.
- **Form Setoran Deposit:**
  - Nominal (Rupiah).
  - Keterangan.
- **Endpoint:** `GET /api/deposit/{customer_code}/saldo`, `GET /api/deposit/{customer_code}/riwayat`, `POST /api/deposit/topup`
