# 📱 Dokumentasi Tim Mobile — PT ENDOG RACING
> Platform: Flutter | Target: Android (min SDK 23)
> Versi: 1.2.0 | Update: 18 Agustus 2026

---

## 🎯 Tujuan Aplikasi

> Aplikasi mobile ini adalah **alat kerja harian** untuk **Anak Kandang** di PT Endog Racing. Setiap hari, anak kandang membuka aplikasi ini untuk:
1. **Absen Masuk** — Check-in dengan selfie + GPS Geofencing
2. **Checklist Harian** — Laporan telur, pakan, kematian, vaksin/obat, kebersihan
3. **Stok Pakan** — Input pemakaian pakan, lihat sisa stok otomatis
4. **Absen Pulang** — Check-out

> Admin juga bisa mengakses via Mobile untuk monitoring (opsional, dengan akun admin terpisah).

---

## 👤 Pengguna Aplikasi Mobile

> ⚠️ **PENTING:** Admin **TIDAK** menggunakan Mobile App.
> Admin menggunakan **Web Panel (Next.js)** untuk konfigurasi dan monitoring.

| Siapa | Cara Login | Akses |
|---|---|---|
| **Anak Kandang** | **ID Kandang** (K1/K2/K3/K4) + PIN 6 digit | Hanya kandang yang dia tangani |
| **Sales** | Username + Password | Fitur sales — Fase 2 (placeholder dulu) |

> **[ATURAN KERAS]** Login menggunakan **ID Kandang**, BUKAN nama karyawan.
> Siapapun yang bertugas hari itu, pakai kode kandang + PIN yang sama.
> Hak akses dibatasi per kandang — anak kandang K1 tidak bisa lihat data K2.

| Platform | Role yang Bisa Akses |
|---|---|
| **Mobile App** | Anak Kandang, Sales |
| **Web Panel** | Admin |

---

## 🗂️ Modul yang Harus Dibuat

---

### MODUL 1: Auth & Login

> **Referensi Visual:** lihat `Mobile/flow_01_login.jpg`

#### Layar 1: Pilih Role
Tampilkan **dua pilihan** saja:
- 🟢 **Anak Kandang** → alur pilih kandang + PIN
- 🟠 **Sales** → placeholder "Coming Soon" (Fase 2)

Tampilkan catatan kecil di bawah: _"Admin → Gunakan Web Panel"_

#### Layar 2A: Login Anak Kandang
```
+-------------------------------+
|   🐔 PT ENDOG RACING          |
|                               |
|   Pilih Kandang:              |
|   [  K1  v  ]                 |  <- Dropdown: K1, K2, K3, K4
|                               |
|   Masukkan PIN:               |
|   [  ●●●●●●  ]               |  <- 6 digit, masked
|                               |
|   [     MASUK     ]           |
|                               |
|   ID Login = ID Kandang,      |
|   bukan nama karyawan         |
+-------------------------------+
```

Error yang harus di-handle:
- "Kode kandang atau PIN salah"
- "Kandang tidak aktif / tidak ditemukan"

#### Layar 2B: Login Sales (Fase 2)
```
+-------------------------------+
|   👔 PT ENDOG RACING          |
|   Portal Sales                |
|                               |
|   Username:                   |
|   [  budi_sales  ]            |
|                               |
|   Password:                   |
|   [  ********    ]            |
|                               |
|   [     MASUK     ]           |
+-------------------------------+
```
- Sales menggunakan kredensial personal.
- Data `sales_id` dan `nama_lengkap` akan diambil dari respons API untuk dilekatkan pada semua transaksi yang mereka buat.

**Session Management:**
- Token disimpan di `FlutterSecureStorage`
- Sertakan `kandang_id` (dari token) di setiap request API
- Session aktif sampai logout atau token expired (24 jam)

---

### MODUL 2: Absensi Geofencing ⭐ PRIORITAS UTAMA

> Modul ini harus selesai PERTAMA. Checklist Harian terkunci sampai absen berhasil.

#### 2.1 Alur Check-In (Absen Masuk)

```
Buka Aplikasi
     |
     v
Cek status absensi hari ini (API)
     |
     +-- Belum absen --> Tampil halaman Absen Masuk
     |
     +-- Sudah absen masuk --> Tampil status + tombol Absen Pulang
     |
     +-- Sudah absen masuk & pulang --> Tampil "Tugas hari ini selesai, sampai jumpa besok!"
```

#### 2.2 Validasi di Sisi Mobile (WAJIB Semua Terpenuhi)

**Geofencing - Cek Lokasi GPS:**
- Ambil koordinat titik pusat kandang dan radius yang di-set Admin dari API.
- Ambil koordinat real-time HP setiap 5 detik (live tracking)
- Hitung jarak ke koordinat kandang (dikirim dari API saat login)
- Tampilkan indikator visual real-time:

```
+-------------------------------+
|  📍 STATUS LOKASI             |
|                               |
|  🟢 DI DALAM AREA KANDANG    |  <- jarak <= 50m
|     Jarak: 23 meter           |
|                               |
|  -- atau --                   |
|                               |
|  🔴 DI LUAR AREA KANDANG     |  <- jarak > 50m
|     Jarak: 120 meter          |
|     Mendekat ke kandang       |
+-------------------------------+
```

- Tombol "Absen" hanya AKTIF jika jarak <= radius (dari config admin)

**[C] Foto Selfie & QR Scanner (Keamanan Lapis 2):**
- Buka kamera front-facing langsung (BUKAN dari galeri) untuk ambil foto wajah.
- Setelah foto wajah, aplikasi otomatis beralih ke mode Scanner Barcode/QR.
- Pekerja **WAJIB** men-scan stiker QR Code fisik yang tertempel di tiang pintu masuk kandang.
- Ini memastikan pekerja benar-benar berada di lokasi fisik (Anti Fake-GPS).

**[D] Submit ke API:**
- Kirim: `foto_selfie` (multipart), `latitude`, `longitude`, `kandang_id`
  - Handle response dari server:
    - `403 OUT_OF_RANGE` -> "Anda di luar area kandang (XXm)"
    - `409 ALREADY_CHECKED_IN` -> "Sudah absen masuk pukul 06:45"

#### 2.3 Layar Absensi Lengkap
```
+------------------------------------------+
|  🐔 PT ENDOG RACING                       |
|  Kandang K1 | Senin, 18 Agustus 2026     |
+------------------------------------------+
|                                          |
|  📍 LOKASI                              |
|  ✅ Di dalam area kandang (23 meter)    |
|                                          |
|  Waktu server: 07:12                    |
|  (Server time, tidak bisa dipalsukan)    |
|  [ AMBIL SELFIE ]                       |
|  [   preview foto di sini   ]           |
|                                          |
|  [      📸 ABSEN MASUK      ]           |  <- BESAR, hijau
|                                          |
+------------------------------------------+
|  📋 Riwayat Absensi Minggu Ini          |
|  Senin   | 06:45 masuk | 15:30 pulang   |
|  Selasa  | 06:50 masuk | 15:45 pulang   |
+------------------------------------------+
```

---

### MODUL 3: Checklist Harian

> Hanya bisa diakses setelah absen masuk berhasil hari itu.
> Checklist terdiri dari 5 sub-form yang harus diisi.

#### 3A. Laporan Produksi Telur

```
+------------------------------------------+
|  🥚 LAPORAN TELUR — K1                   |
|  Senin, 18 Agustus 2026                  |
+------------------------------------------+
|                                          |
|  Jumlah Telur (Butir):                  |
|  [ 900 ]                                |
|                                          |
|  📊 Produktivitas: 90.0%               |  <- OTOMATIS dihitung live
|     (900 / 1000 populasi x 100)         |
|                                          |
|  Jumlah Telur (Kg):                     |
|  [ 45.5 ]                              |  -> Masuk stok inventory
|                                          |
|  Telur Retak (Butir):                   |
|  [ 10 ]                                |  -> Dicatat terpisah
|                                          |
|  Telur Retak (Kg):                      |
|  [ 0.5 ]                               |  -> Tidak masuk stok jual
|                                          |
|  Foto Telur (WAJIB):                    |
|  [ 📸 Ambil Foto ]  [preview]           |
|                                          |
|  [     SIMPAN LAPORAN TELUR     ]       |
+------------------------------------------+
```

**Kalkulasi Otomatis:**
- `% Produktivitas = (butir / populasi_hidup) x 100`
- Ditampilkan LIVE di bawah field input butir (update saat user mengetik)
- Populasi hidup diambil dari data kandang (sudah di-update jika ada kematian)

**Foto Telur:**
- WAJIB — tidak bisa submit tanpa foto
- Gunakan kamera (bukan galeri)
- Foto otomatis mendapat metadata timestamp dari waktu server

---

#### 3B. Laporan Pakan

```
+------------------------------------------+
|  🌾 LAPORAN PAKAN — K1                   |
+------------------------------------------+
|                                          |
|  Stok Pakan Saat Ini:                   |
|  ✅ Siap Pakai  : 45 kg                 |
|  ⚠️  Kena Hama  : 5 kg                  |
|  📦 Total       : 50 kg                 |
|                                          |
|  Pakan Terpakai Hari Ini (Kg):          |
|  [ 10 ]                                |
|                                          |
|  Sisa setelah input:                    |
|  Siap Pakai: 35 kg (preview otomatis)  |
|                                          |
|  Update Stok Kena Hama/Rusak (Kg):     |
|  [ 0 ]  <- opsional, isi jika ada      |
|                                          |
|  [     SIMPAN LAPORAN PAKAN     ]       |
+------------------------------------------+
```

**Logic Stok Pakan:**
- Stok dibagi dua kategori: **Siap Pakai** dan **Kena Hama/Rusak**
- Setiap input pemakaian → kurangi stok "Siap Pakai"
- Admin bisa lihat akumulasi stok dari semua kandang + gudang inti di web
- Jika stok siap pakai < threshold (diatur admin) → tampilkan warning di mobile

---

#### 3C. Laporan Kematian Ayam

```
+------------------------------------------+
|  ☠️  LAPORAN KEMATIAN — K1               |
+------------------------------------------+
|                                          |
|  Populasi Aktif Saat Ini: 1.000 ekor    |
|                                          |
|  Jumlah Ayam Mati Hari Ini:             |
|  [ 2 ]                                 |
|                                          |
|  Populasi setelah laporan:              |
|  998 ekor (preview otomatis)            |
|                                          |
|  Keterangan / Penyebab:                 |
|  [ ............................ ]       |
|                                          |
|  Foto (opsional):                       |
|  [ 📸 Ambil Foto ]                      |
|                                          |
|  [     LAPORKAN KEMATIAN     ]          |
+------------------------------------------+
```

**Efek ke Sistem:**
- `populasi_aktif = populasi_aktif - jumlah_mati` (update langsung di backend)
- Produktivitas telur otomatis akan memakai populasi baru
- Tercatat di data recording

---

#### 3D. Laporan Vaksin & Obat

> Jadwal vaksin dibuat oleh Admin di Web. Di sini anak kandang hanya melaporkan realisasinya.

```
+------------------------------------------+
|  💉 VAKSIN & OBAT — K1                   |
+------------------------------------------+
|                                          |
|  Jadwal Hari Ini:                       |
|  [VAK-001] Vaksin Newcastle             |
|                                          |
|  Tanggal: 18/08/2026 (otomatis, dikunci)|
|                                          |
|  Quantity:                              |
|  [ 1000 ] ekor                         |
|                                          |
|  Dosis Aktual:                          |
|  [ 2 ] ml per ekor                     |
|                                          |
|  Keterangan Kondisi / Sakit Apa:        |
|  [ Ayam terlihat lemas, nafsu makan..  ]|
|                                          |
|  [   SIMPAN LAPORAN VAKSIN   ]          |
+------------------------------------------+
```

**Catatan:**
- Tanggal diambil dari waktu server, tidak bisa diubah
- Item Number vaksin/obat (VAK-001, dll) sudah ditetapkan admin
- Anak kandang tidak bisa menambah item vaksin sendiri

---

#### 3E. Checklist Kebersihan Kandang

```
+------------------------------------------+
|  🧹 KEBERSIHAN KANDANG — K1              |
|  Senin, 18 Agustus 2026                  |
+------------------------------------------+
|                                          |
|  [ ] KB-001: Pembersihan tempat minum   |
|      [📸 Foto Wajib]  [preview]         |
|                                          |
|  [ ] KB-002: Pembersihan tempat pakan   |
|      [📸 Foto Wajib]  [preview]         |
|                                          |
|  [ ] KB-003: Pembersihan lantai kandang |
|      [📸 Foto Wajib]  [preview]         |
|                                          |
|  [   SIMPAN CHECKLIST KEBERSIHAN   ]    |
+------------------------------------------+
```

**Aturan Foto Kebersihan:**
- Setiap item kebersihan WAJIB disertai foto dari kamera (bukan galeri)
- Foto secara otomatis mendapat **watermark tanggal & jam** (dari waktu server)
- Tanggal pada foto **TIDAK BISA diubah** oleh anak kandang
- Item kebersihan bersumber dari `ms_kebersihan` yang dikelola admin

---

### MODUL 4: Dashboard Kandang

Tampil setelah login, sebagai halaman utama:

```
+------------------------------------------+
|  🐔 KANDANG K1                           |
|  Senin, 18 Agustus 2026                  |
|  ✅ Absen Masuk: 06:45 (On-Time)        |
+------------------------------------------+
|                                          |
|  📊 RINGKASAN HARI INI                  |
|  +----------+----------+-----------+    |
|  | Populasi | Telur    | Pakan     |    |
|  | 1.000    | 900 btr  | Siap: 45kg|    |
|  | ekor     | 45.5 kg  | Hama:  5kg|    |
|  +----------+----------+-----------+    |
|                                          |
|  📈 Produktivitas: 90.0%               |
|     (dihitung otomatis)                 |
|                                          |
|  📋 STATUS CHECKLIST HARIAN            |
|  ✅ Laporan Telur                       |
|  ⬜ Laporan Pakan           [Isi Sekarang]|
|  ⬜ Kematian Ayam           [Isi Sekarang]|
|  ⬜ Vaksin & Obat           [Isi Sekarang]|
|  ⬜ Kebersihan Kandang      [Isi Sekarang]|
|                                          |
+------------------------------------------+
|  [📜 Riwayat] [📊 Statistik] [⚙️ Info]  |
+------------------------------------------+
```

---

### MODUL 5: Statistik Produksi Telur

Halaman statistik khusus telur (bukan kematian sebagai fokus):

```
+------------------------------------------+
|  📈 STATISTIK PRODUKSI — K1              |
|  Filter: [ Harian | Mingguan | Bulanan ] |
+------------------------------------------+
|                                          |
|  [Grafik Bar / Line - Produktivitas %]  |
|  Senin  90%  | Selasa 88% | Rabu 91%   |
|                                          |
|  AKUMULASI MINGGU INI:                  |
|  Total Telur: 6.300 butir / 315 kg      |
|  Rata-rata Produktivitas: 89.5%         |
|  Telur Retak: 70 butir / 3.5 kg        |
|  Total Kematian: 5 ekor                 |
|                                          |
+------------------------------------------+
```

---

### MODUL 6: Operasional & Penjualan (Khusus Sales - Fase 2)

Halaman ini hanya muncul jika user login menggunakan akun **Sales** (Username & Password). Sesuai dengan kontrak Perjanjian Jasa ERP, berikut adalah alur kerja Sales:

#### 6A. Absensi Sales & QR Scanner
Berbeda dengan Anak Kandang, Sales melakukan absensi di titik keberangkatan (Gudang Pusat):
- Sales menekan "Absen Masuk", mengambil Foto Selfie, dan **WAJIB men-scan stiker QR Code** di tiang Gudang Pusat.
- Sistem mengunci titik koordinat Gudang Pusat sebagai validasi fisik kehadiran (Anti-Fake GPS).

#### 6B. POS Penjualan Telur (Multi-Harga)
Form pencatatan transaksi penjualan telur ke pelanggan/warung:
- **Lokasi GPS Penjualan:** Saat tombol "Simpan Transaksi" ditekan, aplikasi secara otomatis merekam dan mengirimkan titik GPS saat itu ke server untuk membuktikan Sales benar-benar berada di lokasi toko pelanggan.
- **Sistem Multi-Harga (Proteksi Harga Sentral):** Sales bisa menginput harga penjualan, asalkan **TIDAK LEBIH RENDAH** dari Harga Dasar (Sentral) yang diatur Admin di Web.
- **Metode Pembayaran:** Tersedia opsi penyelesaian transaksi: "Lunas (Tunai/Transfer)" atau "Piutang (Deposit)".

#### 6C. Pencatatan Piutang & Histori Toko
- Sales dapat melihat daftar warung/toko dan memantau saldo sisa tagihan piutang dari masing-masing pelanggan.
- Fitur mencatat cicilan pelunasan dari toko.

#### 6D. Input Pengeluaran / Pembelian Operasional
- Form khusus bagi Sales untuk mencatat pengeluaran operasional (Misal: Beli Bensin, Tol, Makan) menggunakan uang tunai hasil penjualan telur.
- Data pengeluaran ini langsung dikirim ke Backend, berstatus `pending`, menunggu *Approval* dari Admin Web sebelum sah memotong uang di Buku Kas perusahaan.

---
## 📦 Struktur Folder Flutter (Rekomendasi)

```
lib/
├── main.dart
├── core/
│   ├── api/
│   │   ├── api_client.dart         # Dio HTTP client + interceptor
│   │   └── endpoints.dart          # Semua konstanta URL endpoint
│   ├── models/
│   │   ├── kandang_model.dart
│   │   ├── absensi_model.dart
│   │   ├── checklist_model.dart
│   │   └── stok_pakan_model.dart
│   ├── services/
│   │   ├── auth_service.dart       # Login, logout, token management
│   │   ├── location_service.dart   # GPS, geofencing, distance calc
│   │   ├── camera_service.dart     # Kamera, watermark timestamp
│   │   └── notification_service.dart
│   └── utils/
│       ├── constants.dart          # Konstanta app
│       ├── formatters.dart         # Format tanggal, angka, rupiah
│       └── validators.dart         # Validasi form
├── features/
│   ├── auth/
│   │   ├── role_picker_screen.dart
│   │   ├── login_kandang_screen.dart
│   │   └── login_admin_screen.dart
│   ├── absensi/
│   │   ├── absensi_screen.dart     # Main absen screen
│   │   ├── geofence_indicator.dart # Widget indikator lokasi
│   │   └── selfie_camera_screen.dart
│   ├── checklist/
│   │   ├── checklist_home_screen.dart
│   │   ├── laporan_telur_screen.dart
│   │   ├── laporan_pakan_screen.dart
│   │   ├── laporan_kematian_screen.dart
│   │   ├── laporan_vaksin_screen.dart
│   │   └── kebersihan_screen.dart
│   ├── stok/
│   │   └── stok_pakan_screen.dart
│   ├── statistik/
│   │   └── statistik_telur_screen.dart
│   └── dashboard/
│       └── dashboard_screen.dart
└── shared/
    ├── widgets/
    │   ├── geofence_status_card.dart  # Indikator hijau/merah GPS
    │   ├── produktivitas_badge.dart   # Badge % produktivitas
    │   ├── checklist_item_tile.dart
    │   └── stok_pakan_card.dart
    └── themes/
        └── app_theme.dart
```

---

## 📡 API Endpoints yang Dikonsumsi Mobile

> Base URL: `https://api.endogracing.com/api/v1/`
> Auth: `Authorization: Bearer {token}` di semua endpoint (kecuali login)

| Method | Endpoint | Fungsi |
|---|---|---|
| POST | `/auth/login-kandang` | Login dengan ID Kandang + PIN |
| POST | `/auth/login` | Login Admin (Web Panel) |
| POST | `/auth/logout` | Logout |
| POST | `/absensi/checkin` | Absen masuk (foto + GPS + kandang_id) |
| POST | `/absensi/checkout` | Absen pulang |
| GET | `/absensi/today/{kandang_id}` | Status absensi hari ini |
| GET | `/dashboard/kandang/{id}` | Summary kandang (populasi, telur, stok) |
| POST | `/checklist/telur` | Submit laporan telur (dengan foto) |
| POST | `/checklist/pakan` | Submit laporan pakan |
| POST | `/checklist/kematian` | Submit laporan kematian |
| POST | `/checklist/vaksin` | Submit laporan vaksin/obat |
| POST | `/checklist/kebersihan` | Submit checklist kebersihan (dengan foto bertanggal) |
| GET | `/kandang/{id}/stok-pakan` | Detail stok pakan (siap pakai vs kena hama) |
| GET | `/kandang/{id}/jadwal-vaksin` | Jadwal vaksin hari ini dari admin |
| GET | `/kandang/{id}/statistik` | Data statistik produksi telur |
| POST | `/sales/penjualan` | Submit POS Penjualan (Beserta GPS toko & nominal) |
| POST | `/sales/pengeluaran` | Input pengeluaran operasional bensin/tol (Pending Approval) |
| GET | `/sales/piutang` | Cek sisa piutang/deposit toko langganan |
| GET | `/recording/{kandang_id}` | Riwayat semua kejadian (data recording) |

---

## 🔒 Izin Aplikasi (Android Permissions)

```xml
<!-- AndroidManifest.xml -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

> `CAMERA` dan `ACCESS_FINE_LOCATION` harus di-request saat runtime (bukan hanya di manifest).

---

## 📦 Dependencies Flutter (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # HTTP & API
  dio: ^5.4.0

  # State Management
  flutter_bloc: ^8.1.4

  # Secure Local Storage
  flutter_secure_storage: ^9.0.0
  shared_preferences: ^2.2.2

  # Geolocation & GPS
  geolocator: ^11.0.0
  permission_handler: ^11.3.0

  # Kamera (TIDAK pakai image_picker dari galeri untuk selfie & kebersihan)
  camera: ^0.10.5+9

  # Watermark Tanggal pada Foto Kebersihan
  image: ^4.1.7

  # Maps (visualisasi radius geofence)
  google_maps_flutter: ^2.6.0

  # Charts (statistik produksi)
  fl_chart: ^0.68.0

  # Utils
  intl: ^0.19.0
  cached_network_image: ^3.3.1
```

---

## ✅ Checklist Testing Sebelum Handover

### Auth & Login
- [ ] Login Kandang (K1-K4) berhasil, token tersimpan di SecureStorage
- [ ] Login Admin berhasil, bisa akses semua kandang
- [ ] Logout berhasil, token terhapus dari storage

### Absensi Geofencing
- [ ] Izin GPS & Kamera diminta saat pertama buka
- [ ] Indikator lokasi berubah hijau/merah secara real-time
- [ ] Tombol absen DISABLE saat di luar radius (>50m)
- [ ] Foto selfie wajib dari kamera (tombol disable tanpa foto)
- [ ] Data GPS + foto terkirim ke API
- [ ] Pesan error dari API (403/409) ditampilkan dengan jelas di UI

### Checklist Harian
- [ ] Semua sub-form terkunci jika belum absen hari ini
- [ ] % Produktivitas dihitung live saat user ketik jumlah butir
- [ ] Telur retak dicatat terpisah dan TIDAK menambah stok jual
- [ ] Stok pakan berkurang setelah laporan pakan disubmit
- [ ] Stok pakan tampilkan dua kategori: Siap Pakai & Kena Hama
- [ ] Populasi berkurang setelah laporan kematian disubmit
- [ ] Foto kebersihan wajib ada watermark tanggal dari server
- [ ] Tanggal foto kebersihan tidak bisa diubah
- [ ] Jadwal vaksin dari admin muncul otomatis di form vaksin

### Dashboard & Statistik
- [ ] Dashboard menampilkan ringkasan hari ini (telur, pakan, populasi, produktivitas)
- [ ] Status checklist harian tampil dengan benar (sudah/belum isi)
- [ ] Halaman statistik menampilkan grafik tren produktivitas
- [ ] Filter harian/mingguan/bulanan berfungsi pada statistik