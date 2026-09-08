# Dokumentasi API Endog Racing

Dokumen ini memuat spesifikasi dari setiap *endpoint* API yang digunakan pada aplikasi Endog Racing.
*(Wajib menyertakan header `Accept: application/json` pada setiap request)*

---

## 1. Authentication (Login)

### 1.1 Login Web (Admin & Owner)
Endpoint ini digunakan untuk *login* ke aplikasi Web Dashboard.

- **URL**: `POST /api/login/web`
- **Auth Required**: No
- **Payload (JSON)**:
```json
{
  "usr_loginname": "admin_budi",
  "usr_password": "Password123!"
}
```
- **Success Response (200 OK)**:
```json
{
  "message": "Login Web berhasil",
  "access_token": "1|xxxxxxxxxxxxxxx",
  "token_type": "Bearer",
  "user": {
    "id": 1,
    "usr_loginname": "admin_budi",
    "usr_rolecode": "Admin",
    "emp_code": "EMP-202608200001"
  }
}
```

### 1.2 Login Mobile - Sales
Endpoint ini digunakan untuk *login* khusus kurir/sales di aplikasi Mobile.

- **URL**: `POST /api/login/sales`
- **Auth Required**: No
- **Payload (JSON)**:
```json
{
  "usr_loginname": "sales_joko",
  "usr_password": "Password123!"
}
```
- **Success Response (200 OK)**: Sama seperti Login Web.

### 1.3 Login Mobile - Kandang (Kiosk Mode)
Endpoint ini digunakan untuk *login* khusus tablet/perangkat yang diam di area kandang. Petugas tidak perlu memasukkan *username*/*password*, cukup memilih Kandang dan memasukkan PIN.

- **URL**: `POST /api/login/kandang`
- **Auth Required**: No
- **Prerequisite**: Gunakan `GET /api/kandang/list` (Tanpa Auth) untuk mendapatkan daftar `kdg_code` dan nama kandang untuk ditampilkan di *dropdown* aplikasi.
- **Payload (JSON)**:
```json
{
  "kdg_code": "KDG-001",
  "kdg_pin": "123456"
}
```
- **Success Response (200 OK)**:
```json
{
  "message": "Login Kandang berhasil",
  "access_token": "2|xxxxxxxxxxxxxxx",
  "token_type": "Bearer",
  "kandang": {
    "kdg_code": "KDG-001",
    "kdg_nama": "Kandang Layer A"
  }
}
```

### 1.4 Verify Barcode Kandang (Mobile Kandang Shortcut)
Endpoint ini digunakan oleh aplikasi Mobile untuk menerjemahkan angka Barcode hasil *scan* kamera menjadi ID Kandang. Jika sukses, Mobile akan langsung menyuguhkan form PIN untuk Kandang tersebut, dan selanjutnya tetap memanggil `POST /api/login/kandang`.

- **URL**: `POST /api/kandang/verify-barcode`
- **Auth Required**: No
- **Payload (JSON)**:
```json
{
  "barcode": "BRC-KDG-001"
}
```
- **Success Response (200 OK)**:
```json
{
  "status": "success",
  "data": {
    "kdg_code": "KDG-001",
    "kdg_nama": "Kandang Layer A"
  }
}
```
- **Error Response (404 Not Found)**:
```json
{
  "status": "error",
  "message": "Barcode tidak dikenal / Kandang tidak ditemukan!"
}
```

### 1.5 Dashboard Kandang (Mobile)
Endpoint ini digunakan untuk mengambil ringkasan metrik (Flow dan Snapshot) serta status aktivitas harian kandang yang sedang login.

- **URL**: `GET /api/kandang/dashboard`
- **Query Params**: `?filter=harian` (Opsi yang tersedia: `harian`, `mingguan`, `bulanan`. Default: `harian`)
- **Auth Required**: Yes (Bearer Token, Role: Kandang)
- **Success Response (200 OK)**:
```json
{
  "message": "Success",
  "filter": "harian",
  "data": {
    "metrik": {
      "pakan_terpakai_kg": 125.0,
      "telur_hari_ini_kg": 85.2,
      "telur_rusak_kg": 2.4,
      "kematian_ekor": 5,
      "total_populasi_ekor": 10500,
      "sisa_stok_pakan_kg": 4500.0
    },
    "aktivitas": {
      "is_absen_masuk_done": true,
      "ceklist_rutin_done": 5,
      "ceklist_rutin_total": 5,
      "is_pakan_harian_done": true,
      "is_produksi_telur_done": true
    }
  }
}
```
*(Catatan: Filter rentang waktu Harian/Mingguan/Bulanan hanya berdampak pada 4 data teratas di dalam `metrik`. Untuk `total_populasi_ekor` dan `sisa_stok_pakan_kg` adalah data saldo riil saat ini (snapshot), sedangkan data di `aktivitas` selalu mengecek status hari ini)*.

---

## 2. User Management (Master)

**PENTING**: Semua Data Master kini wajib menggunakan awalan `/api/master/`.

### 2.1 Create Pegawai & User Baru
Endpoint ini digunakan oleh Admin Web untuk mendaftarkan akun pegawai baru. Sistem otomatis membuat data di tabel `ms_employee` dan `ms_user` sebagai satu kesatuan.

- **URL**: `POST /api/master/users`
- **Auth Required**: Yes (Bearer Token, Role: Admin/Owner)
- **Payload (JSON)**:
```json
{
  "emp_name": "Agus Santoso",
  "emp_jabatan": "Mandor",
  "emp_telp": "08123456789",
  "emp_alamat": "Jl. Peternakan No 1",
  "usr_loginname": "mandor_agus",
  "usr_email": "agus@endogracing.com",
  "usr_password": "Password123!",
  "usr_rolecode": "Kandang"
}
```
*(Catatan: `usr_rolecode` bisa diisi: `Owner`, `Admin`, `Sales`, atau `Kandang`)*

- **Success Response (201 Created)**:
```json
{
  "message": "Pengguna dan Pegawai berhasil didaftarkan.",
  "data": {
    "id": 2,
    "usr_loginname": "mandor_agus",
    "usr_email": "agus@endogracing.com",
    "usr_rolecode": "Kandang",
    "emp_code": "EMP-202608200001",
    "usr_status": "Aktif",
    "employee": {
      "emp_code": "EMP-202608200001",
      "emp_name": "Agus Santoso",
      "emp_jabatan": "Mandor",
      "emp_telp": "08123456789",
      "emp_alamat": "Jl. Peternakan No 1",
      "rec_status": "Aktif"
    }
  }
}
```

### 2.2 Get All Users
Mendapatkan daftar seluruh pengguna beserta profil pegawainya.
- **URL**: `GET /api/master/users`
- **Auth Required**: Yes (Bearer Token, Role: Admin/Owner)

### 2.3 Get Specific User
Mendapatkan detail profil satu pengguna.
- **URL**: `GET /api/master/users/{emp_code}`
- **Auth Required**: Yes (Bearer Token, Role: Admin/Owner)

### 2.4 Update Profil User
Mengubah data profil pegawai dan role/status pengguna. Semua *field* bersifat opsional.
- **URL**: `PUT /api/master/users/{emp_code}`
- **Auth Required**: Yes (Bearer Token, Role: Admin/Owner)
- **Payload (JSON) Contoh**:
```json
{
  "emp_name": "Agus Santoso Siregar",
  "emp_jabatan": "Mandor Kepala",
  "usr_status": "Aktif"
}
```

### 2.5 Nonaktifkan User (Soft Delete)
Menonaktifkan akses *login* pengguna tanpa menghapus datanya dari database untuk menjaga historis pelaporan.
- **URL**: `DELETE /api/master/users/{emp_code}`
- **Auth Required**: Yes (Bearer Token, Role: Admin/Owner)
- **Success Response (200 OK)**:
```json
{
  "message": "Pengguna berhasil dinonaktifkan (Soft Delete)."
}
```

---

## 3. Data Master

### CRUD ms_kandang
- **GET** `/api/master/kandang` (List all)
- **GET** `/api/master/kandang/{kdg_code}` (Detail)
- **GET** `/api/master/kandang/{kdg_code}/barcode` (Menampilkan UI HTML/Gambar Barcode untuk di-print)
- **DELETE** `/api/master/kandang/{kdg_code}` (Soft delete)
- **POST** `/api/master/kandang` (Create - otomatis membuat kdg_barcode)
- **PUT** `/api/master/kandang/{kdg_code}` (Update)

**Payload (JSON) untuk POST / PUT:**
```json
{
    "kdg_code": "KDG-001",
    "kdg_nama": "Kandang Layer Utama",
    "kdg_kapasitas": 5000,
    "kdg_alamat": "Jl. Peternakan No. 1, Bandung",
    "kdg_longitude": "107.6191",
    "kdg_latitude": "-6.9175",
    "kdg_pin": "123456"
}
```
*(Auth: Bearer Token, Role: Owner/Admin)*

### CRUD ms_gudang
- **GET** `/api/master/gudang` (List all)
- **GET** `/api/master/gudang/{gudang_code}` (Detail)
- **DELETE** `/api/master/gudang/{gudang_code}` (Soft delete)
- **POST** `/api/master/gudang` (Create)
- **PUT** `/api/master/gudang/{gudang_code}` (Update)

**Payload (JSON) untuk POST / PUT:**
```json
{
    "gudang_code": "GDG-001",
    "gudang_nama": "Gudang Pakan A",
    "gudang_tipe": "Pakan",
    "kdg_code": "KDG-001",
    "gudang_desc": "Penyimpanan utama pakan ayam"
}
```
*(Auth: Bearer Token, Role: Owner/Admin)*

### CRUD ms_product_business
- **GET** `/api/master/product-business` (List all)
- **GET** `/api/master/product-business/{sku_product}` (Detail)
- **DELETE** `/api/master/product-business/{sku_product}` (Soft delete)
- **POST** `/api/master/product-business` (Create)
- **PUT** `/api/master/product-business/{sku_product}` (Update)

**Payload (JSON) untuk POST / PUT:**
```json
{
    "sku_product": "PRD-001",
    "sku_name": "Pakan Ayam Starter",
    "sku_category": "Pakan",
    "sku_uom": "KG",
    "sku_uom_secondary": "Sak",
    "sku_uom_conversion": 50,
    "sku_description": "Pakan khusus DOC"
}
```
*(Auth: Bearer Token, Role: Owner/Admin)*

### CRUD ms_cogs
- **GET** `/api/master/cogs` (List all)
- **GET** `/api/master/cogs/{cogs_id}` (Detail)
- **DELETE** `/api/master/cogs/{cogs_id}` (Soft delete)
- **POST** `/api/master/cogs` (Create)
- **PUT** `/api/master/cogs/{cogs_id}` (Update)

**Payload (JSON) untuk POST / PUT:**
```json
{
    "sku_product": "PRD-001",
    "cogs_price": 150000.00,
    "cogs_effective_date": "2026-08-21"
}
```
*(Auth: Bearer Token, Role: Owner/Admin)*

### CRUD ms_supplier
- **GET** `/api/master/supplier` (List all)
- **GET** `/api/master/supplier/{supplier_code}` (Detail)
- **DELETE** `/api/master/supplier/{supplier_code}` (Soft delete)
- **POST** `/api/master/supplier` (Create)
- **PUT** `/api/master/supplier/{supplier_code}` (Update)

**Payload (JSON) untuk POST / PUT:**
```json
{
    "supplier_code": "SUP-001",
    "supplier_name": "PT Pakan Jaya Abadi",
    "supplier_address": "Kawasan Industri Kendal",
    "supplier_phone": "081234567890",
    "supplier_email": "sales@pakanjaya.com"
}
```
*(Auth: Bearer Token, Role: Owner/Admin)*

### CRUD ms_kebersihan
- **GET** `/api/master/kebersihan` (List all)
- **GET** `/api/master/kebersihan/{kbrshn_code}` (Detail)
- **DELETE** `/api/master/kebersihan/{kbrshn_code}` (Soft delete)
- **POST** `/api/master/kebersihan` (Create)
- **PUT** `/api/master/kebersihan/{kbrshn_code}` (Update)

**Payload (JSON) untuk POST / PUT:**
```json
{
    "kbrshn_code": "KBR-001",
    "kbrshn_nama": "Pembersihan Kandang Mingguan",
    "kbrshn_frekuensi": "Mingguan",
    "kbrshn_desc": "Cuci kandang dan sanitasi"
}
```
*(Auth: Bearer Token, Role: Owner/Admin)*

### CRUD ms_customer
- **GET** `/api/master/customer` (List all)
- **GET** `/api/master/customer/{customer_code}` (Detail)
- **DELETE** `/api/master/customer/{customer_code}` (Soft delete)
- **POST** `/api/master/customer` (Create)
- **PUT** `/api/master/customer/{customer_code}` (Update)

**Payload (JSON) untuk POST / PUT:**
```json
{
    "customer_code": "CST-001",
    "customer_name": "Toko Telur Berkah",
    "customer_address": "Pasar Induk Kramat Jati",
    "customer_phone": "081987654321",
    "customer_tipe": "Grosir"
}
```
*(Auth: Bearer Token, Role: Owner/Admin)*

### CRUD ms_coa
- **GET** `/api/master/coa` (List all)
- **GET** `/api/master/coa/{coa_code}` (Detail)
- **DELETE** `/api/master/coa/{coa_code}` (Soft delete)
- **POST** `/api/master/coa` (Create)
- **PUT** `/api/master/coa/{coa_code}` (Update)

**Payload (JSON) untuk POST / PUT:**
```json
{
    "coa_code": "1-1001",
    "coa_nama": "Kas Kecil",
    "coa_tipe": "Asset",
    "coa_desc": "Kas tunai di kantor"
}
```
*(Auth: Bearer Token, Role: Owner/Admin)*

### CRUD ms_periode_kandang
- **GET** `/api/master/periode-kandang` (List all)
- **GET** `/api/master/periode-kandang/{prd_code}` (Detail)
- **DELETE** `/api/master/periode-kandang/{prd_code}` (Soft delete)
- **POST** `/api/master/periode-kandang` (Create)
- **PUT** `/api/master/periode-kandang/{prd_code}` (Update)

**Payload (JSON) untuk POST / PUT:**
```json
{
    "prd_code": "PRD-KDG-001-2026",
    "kdg_code": "KDG-001",
    "prd_tanggal_masuk": "2026-08-01",
    "prd_populasi_awal": 5000,
    "prd_umur_awal_minggu": 16,
    "prd_status_periode": "Aktif"
}
```
*(Auth: Bearer Token, Role: Owner/Admin)*

### CRUD ms_penyakit
- **GET** `/api/master/penyakit` (List all)
- **GET** `/api/master/penyakit/{penyakit_code}` (Detail)
- **DELETE** `/api/master/penyakit/{penyakit_code}` (Soft delete)
- **POST** `/api/master/penyakit` (Create)
- **PUT** `/api/master/penyakit/{penyakit_code}` (Update)

**Payload (JSON) untuk POST / PUT:**
```json
{
    "penyakit_code": "PYK-001",
    "penyakit_nama": "Flu Burung (Avian Influenza)",
    "penyakit_kategori": "Virus",
    "penyakit_desc": "Sangat menular, fatal"
}
```
*(Auth: Bearer Token, Role: Owner/Admin)*

### CRUD ms_kas_bank
- **GET** `/api/master/kas-bank` (List all)
- **GET** `/api/master/kas-bank/{kas_bank_code}` (Detail)
- **DELETE** `/api/master/kas-bank/{kas_bank_code}` (Soft delete)
- **POST** `/api/master/kas-bank` (Create)
- **PUT** `/api/master/kas-bank/{kas_bank_code}` (Update)

**Payload (JSON) untuk POST / PUT:**
```json
{
    "kas_bank_code": "KB-001",
    "kas_bank_nama": "BCA Cabang Sudirman",
    "kas_bank_jenis": "Bank",
    "kas_bank_norek": "1234567890",
    "kas_bank_atasnama": "PT Endog Racing"
}
```
*(Auth: Bearer Token, Role: Owner/Admin)*

---

## 4. Data Transaksi

### Transaksi Absensi (Mobile Kandang)
Digunakan oleh aplikasi Mobile Kandang untuk mencatat absen Masuk dan absen Pulang.

- **GET** `/api/absensi` (Melihat riwayat absen)
- **POST** `/api/absensi` (Kirim absen)

**Payload (multipart/form-data) untuk POST:**
- `abs_tipe_absen` : `Masuk`
- `abs_foto_selfie`: *(Pilih tipe File, masukkan foto)*
- `abs_latitude`   : `-6.91750000`
- `abs_longitude`  : `107.61910000`

### Transaksi Mutasi Stok Gudang (Admin)
- **GET** `/api/mutasi-stock`

### Transaksi Produksi Telur (Mobile Kandang)
- **GET** `/api/produksi-telur` (List riwayat panen)
- **POST** `/api/produksi-telur` (Input panen)

**Payload (JSON) untuk POST:**
```json
{
  "prd_code": "PRD-KDG-001-2026",
  "gudang_code": "GDG-PUSAT",
  "tanggal": "2026-08-23",
  "details": [
    {
      "sku_product": "SKU-TELUR-BAGUS",
      "qty_butir": 1000,
      "qty_kg": 60.5
    }
  ]
}
```

### Transaksi Pemakaian Pakan (Mobile Kandang)
- **POST** `/api/pemakaian-pakan`
  - **Payload (JSON)**:
  ```json
  {
      "gudang_code": "GDG-001",
      "kdg_code": "KDG-001",
      "tanggal": "2026-08-23",
      "sku_product": "PKN-001",
      "qty_pakai": 5
  }
  ```

### Transaksi Kematian Ayam (Mobile Kandang)
- **POST** `/api/kematian-ayam`
  - **Payload (JSON)**:
  ```json
  {
      "kdg_code": "KDG-001",
      "prd_code": "PRD-2026-08",
      "tanggal": "2026-08-23",
      "penyakit_code": "PYK-001",
      "jumlah_mati": 10
  }
  ```

### Transaksi Afkir Ayam (Mobile Kandang)
- **POST** `/api/afkir-ayam`
  - **Payload (JSON)**:
  ```json
  {
      "kdg_code": "KDG-001",
      "prd_code": "PRD-2026-08",
      "gudang_code": "GDG-001",
      "tanggal": "2026-08-23",
      "sku_product": "AFK-001",
      "jumlah_ekor": 20
  }
  ```

### Transaksi Checklist Kebersihan (Mobile Kandang)
- **POST** `/api/checklist-kandang`
  - **Payload (JSON)**:
  ```json
  {
      "kdg_code": "KDG-001",
      "tanggal": "2026-08-23",
      "kbrshn_code": "KBR-001",
      "status": "Selesai",
      "keterangan": "Kandang sudah disapu dan disemprot disinfektan"
  }
  ```

### Transaksi Penjualan Telur (Mobile Sales)
- **POST** `/api/penjualan`
  - **Payload (JSON)**:
  ```json
  {
      "customer_code": "CUST-001",
      "tanggal": "2026-08-23",
      "details": [
          {
              "sku_product": "TLR-001",
              "qty": 50,
              "harga_satuan": 30000
          }
      ]
  }
  ```

#### Transaksi Pembelian (Web Admin)
Modul untuk mengelola Purchase Order (PO) ke Supplier dan melakukan **Validasi Akhir (Approve/Reject)** terhadap barang yang telah diterima oleh Kandang.

- **GET** `/api/pembelian/pending`
  - *List semua PO yang statusnya masih 'Belum Diterima' DAN belum memiliki Draft Penerimaan Barang. Endpoint ini khusus digunakan untuk mengisi data **Dropdown PO** di aplikasi Penerimaan Barang (Kandang).*
- **GET** `/api/pembelian`
  - *List semua PO lengkap dengan relasi Supplier & Gudang (Diurutkan dari terbaru).*
  - *Data JSON dikembalikan dalam format **Paginasi** (25 baris/halaman).*
  - **Query Parameters (Opsional):**
    - `page` (int) - Untuk navigasi halaman (default 1).
    - `start_date` (YYYY-MM-DD) - Filter tanggal awal.
    - `end_date` (YYYY-MM-DD) - Filter tanggal akhir.
- **POST** `/api/pembelian`
  - *Create PO Baru (Payload JSON `details` wajib disertakan). **Catatan Penting untuk Frontend:** Anda tidak perlu mengirimkan `harga_satuan` karena sistem backend otomatis menarik harga dari tabel Master Data.*
  ```json
  {
      "supplier_code": "SUP-001",
      "gudang_code": "GDG-001",
      "tanggal": "2026-08-25",
      "details": [
          {
              "sku_product": "PRD-001",
              "qty": 100
          },
          {
              "sku_product": "PRD-002",
              "qty": 50
          }
      ]
  }
  ```
- **GET** `/api/pembelian/{po_h}`
  - *Lihat detail lengkap satu PO beserta item-itemnya*
- **PUT** `/api/pembelian/{po_h}`
  - *Update PO (Hanya berlaku jika status masih 'Pending'). Struktur Payload sama persis dengan POST di atas*
- **DELETE** `/api/pembelian/{po_h}`
  - *Menghapus PO dan otomatis menghapus detail itemnya (Hanya jika masih 'Pending')*
- **POST** `/api/pembelian/{po_h}/approve`
  - *Admin menyetujui penerimaan barang. Mengubah `status_approval` PO menjadi 'Approved' dan `status_penerimaan` menjadi 'Selesai'. Endpoint ini **HANYA BISA DIEKSEKUSI** jika Anak Kandang sudah menginput Draft Penerimaan Barang. Endpoint ini **Otomatis akan mengeksekusi Mutasi Stok IN** ke Gudang (berdasarkan qty penerimaan aktual dari kandang).*
- **POST** `/api/pembelian/{po_h}/reject`
  - *Admin menolak penerimaan barang (karena ada ketidaksesuaian laporan kandang). Mengubah `status_approval` PO menjadi 'Rejected'. Stok gudang **tidak** bertambah.*
- **GET** `/api/pembelian/{po_h}/pdf`
  - *Men-generate dan mencetak dokumen Purchase Order dalam bentuk PDF.*

### Transaksi Penerimaan Barang / Good Receipt (Mobile Kandang)
Pengecekan fisik barang aktual berdasar PO saat barang datang ke kandang. Anak Kandang hanya bertugas **menyimpan Laporan Draft**. Keputusan akhir mutasi stok berada di tangan Admin Web.

- **GET** `/api/penerimaan-barang`
  - *Melihat daftar histori penerimaan barang (Diurutkan dari terbaru).*
  - *Data JSON dikembalikan dalam format **Paginasi** (25 baris/halaman).*
- **GET** `/api/penerimaan-barang/{terima_code}`
  - *Melihat detail penerimaan barang tertentu beserta item-item aktual yang diterima.*
- **POST** `/api/penerimaan-barang`
  - *Mencatat Laporan Draft Penerimaan Barang berdasarkan PO. Endpoint ini **TIDAK** menambah mutasi stok gudang. Hanya menyimpan laporan untuk divalidasi Admin.*
  - **Payload (JSON)**:
  ```json
  {
      "po_h": "PO-GDG-001-20260825-001",
      "tanggal_terima": "2026-08-25",
      "penerima_name": "Supir Budi",
      "no_surat_jalan": "DO-998877",
      "foto_surat_jalan": null,
      "details": [
          {
              "sku_product": "PRD-001",
              "qty_po": 100,
              "qty_terima": 100
          },
          {
              "sku_product": "PRD-002",
              "qty_po": 50,
              "qty_terima": 45
          }
      ]
  }
  ```

**Payload (multipart/form-data) untuk POST (Jika kirim foto):**
- `po_h` : `PO-GDG-001-20260825-001`
- `tanggal_terima`: `2026-08-25`
- `penerima_name` : `Budi Supir`
- `no_surat_jalan` : `DO-998877`
- `foto_surat_jalan`: *(Pilih File)*
- `details[0][sku_product]`: `PRD-001`
- `details[0][qty_po]`: `100.00`
- `details[0][qty_terima]`: `98.00`

- **GET** `/api/penerimaan-barang/{terima_code}/pdf`
  - *Meng-generate dokumen PDF Bukti Penerimaan Barang (lengkap dengan foto surat jalan). Endpoint ini diakses Admin sebelum melakukan Approve/Reject.*
- **DELETE** `/api/penerimaan-barang/{terima_code}`
  - *Membatalkan / menghapus Laporan Draft Penerimaan Barang (beserta foto dan detailnya). Hanya bisa dilakukan jika PO belum berstatus Selesai.*


### Transaksi Penurunan Pakan (Web Admin)
- **POST** `/api/penurunan-pakan`

### Inventory & Stok Gudang
Modul untuk melihat total saldo stok barang terkini dan melacak history pergerakan (keluar/masuk) barang di tiap gudang.

- **GET** `/api/inventory/stok`
  - *Menampilkan daftar saldo akhir setiap produk di tiap gudang.*
  - **Query Parameters (Opsional):**
    - `gudang_code`: Filter berdasarkan kode gudang tertentu (misal: `GDG-001`).
  - **Contoh Response:**
  ```json
  "data": [
      {
          "gudang_code": "GDG-001",
          "gudang_name": "Gudang Kandang 1",
          "sku_product": "PRD-001",
          "sku_name": "Pakan Ayam Starter",
          "sku_uom": "Sak",
          "stock_akhir": 48,
          "terakhir_update": "2026-08-25 15:30:00"
      }
  ]
  ```

- **GET** `/api/inventory/mutasi`
  - *Menampilkan "Kartu Stok" atau buku mutasi pergerakan barang (IN/OUT).*
  - *Data JSON dikembalikan dalam format **Paginasi**.*
  - **Query Parameters (Opsional):**
    - `gudang_code`: Filter berdasarkan kode gudang tertentu.
    - `sku_product`: Filter berdasarkan produk tertentu.
    - `start_date` & `end_date`: Filter rentang tanggal transaksi.
  - **Contoh Response:**
  ```json
  "data": [
      {
          "id": 15,
          "gudang_code": "GDG-001",
          "sku_product": "PRD-001",
          "qty_in": "50.00",
          "qty_out": "0.00",
          "stock_akhir": "50.00",
          "ref_no": "PB-GDG-001-20260825-001",
          "keterangan": "Mutasi IN dari Penerimaan Barang"
      }
  ]
  ```

### Transaksi Penggajian (Web Admin)
- **POST** `/api/penggajian`
  - **Payload (JSON)**:
  ```json
  {
      "emp_code": "EMP-001",
      "tanggal": "2026-08-23",
      "total_gaji": 3500000,
      "keterangan": "Gaji Bulan Agustus"
  }
  ```
### Transaksi Pemakaian Pakan (Mobile Kandang)
- **GET** `/api/pemakaian-pakan/form?gudang_code={gudang_code}`
  - *Membentuk form otomatis berisikan daftar semua produk ber-kategori 'Pakan' beserta `stock_tersedia`-nya di gudang tersebut. Endpoint ini dipakai Frontend agar Anak Kandang tidak perlu repot mencari SKU Pakan satu per satu.*
- **GET** `/api/pemakaian-pakan`
  - *Melihat daftar histori pemakaian pakan.*
- **POST** `/api/pemakaian-pakan`
  - *Mencatat pemakaian pakan harian ke kandang. (Otomatis mengurangi stok gudang dan mengaitkan biaya ke Periode Kandang aktif).*
  - **Payload (JSON)**:
  ```json
  {
      "gudang_code": "GDG-001",
      "kdg_code": "KDG-001",
      "tanggal": "2026-08-24",
      "details": [
          {
              "sku_product": "PKN-001",
              "qty_pakai": 5
          },
          {
              "sku_product": "PKN-002",
              "qty_pakai": 2.5
          }
      ]
  }
  ```

### Transaksi Produksi Telur Harian (Mobile Kandang)
Modul untuk mencatat hasil panen telur (utuh & rusak) per hari.

- **GET** `/api/produksi-telur/form?kdg_code={kdg_code}`
  - *Mengambil data populasi ayam saat ini (dari master siklus/periode aktif) untuk bahan kalkulasi "Persentase Produktivitas / Hen-Day" secara real-time di UI Mobile.*
  - **Contoh Response:**
  ```json
  {
      "prd_code": "PRD-2026-001",
      "kdg_code": "KDG-001",
      "populasi_ayam_saat_ini": 5000 
  }
  ```
- **GET** `/api/produksi-telur`
  - *Melihat daftar histori laporan produksi telur.*
  - **Query Parameters (Opsional):** `kdg_code`, `start_date`, `end_date`.
- **POST** `/api/produksi-telur`
  - *Mencatat laporan panen telur harian. Endpoint ini otomatis menambah stok gudang (Mutasi IN) menggunakan satuan berat (KG).*
  - **Payload (JSON)**:
  ```json
  {
      "kdg_code": "KDG-001",
      "gudang_code": "GDG-001",
      "tanggal": "2026-08-25",
      "details": [
          {
              "sku_product": "PRD-005",
              "kategori": "Utuh",
              "qty_butir": 100,
              "qty_kg": 6.5
          },
          {
              "sku_product": "PRD-006",
              "kategori": "Rusak",
              "qty_butir": 5,
              "qty_kg": 0.3
          }
      ]
  }
  ```

### Transaksi Pemakaian Obat & Vaksin (Mobile Kandang)
- **POST** `/api/pemakaian-obat`
  - **Payload (JSON)**:
  ```json
  {
      "gudang_code": "GDG-001",
      "kdg_code": "KDG-001",
      "tanggal": "2026-08-23",
      "sku_product": "OBT-001",
      "qty_pakai": 2
  }
  ```

### Transaksi Stock Opname (Web Admin)
- **POST** `/api/stock-opname`
  - **Payload (JSON)**:
  ```json
  {
      "gudang_code": "GDG-001",
      "tanggal": "2026-08-23",
      "sku_product": "PKN-001",
      "selisih": -2,
      "keterangan": "2 Karung rusak dimakan tikus"
  }
  ```

### Transaksi Pengeluaran Kas / Overhead (Web Admin)
- **POST** `/api/pengeluaran-kas`
  - **Payload (JSON)**:
  ```json
  {
      "coa_code": "COA-500",
      "tanggal": "2026-08-23",
      "nominal": 150000,
      "keterangan": "Beli Token Listrik Kandang"
  }
  ```

### Transaksi Retur Beli (Web Admin)
- **POST** `/api/retur-beli`
  - **Payload (JSON)**:
  ```json
  {
      "po_h": "PO-GDG-001-20260823-001",
      "tanggal": "2026-08-23",
      "keterangan": "Barang basi",
      "details": [
          {
              "sku_product": "PKN-001",
              "qty_retur": 5
          }
      ]
  }
  ```

### Transaksi Retur Jual (Web Admin)
- **POST** `/api/retur-jual`
  - **Payload (JSON)**:
  ```json
  {
      "jual_code": "SLS-20260823-001",
      "tanggal": "2026-08-23",
      "keterangan": "Telur pecah di jalan",
      "details": [
          {
              "sku_product": "TLR-001",
              "qty_retur": 2
          }
      ]
  }
  ```

### Transaksi Produksi Telur (Mobile Kandang & Web Admin)
Pencatatan produksi telur harian dari kandang. Sistem akan otomatis merekam stok masuk (mutasi stok) ke gudang kandang tersebut.

- **GET** `/api/produksi-telur`
  - *Melihat daftar histori produksi telur beserta detailnya.*
- **GET** `/api/produksi-telur/{produksi_code}`
  - *Melihat detail produksi telur tertentu.*
- **POST** `/api/produksi-telur`
  - *Mencatat produksi telur baru. ID akan di-generate otomatis (`PRD-{kdg}-{tgl}-{urut}`).*
  - **Payload (JSON)**:
  ```json
  {
      "kdg_code": "KDG-001",
      "gudang_code": "GDG-001", 
      "prd_code": "PRD-2026-08",
      "tanggal": "2026-08-24",
      "sku_product": "TLR-001",
      "kategori": "Utuh", 
      "qty_butir": 500,
      "qty_kg": 30.5
  }
  ```
  *(Catatan: Anda wajib mengisi `kategori` dengan nilai `Utuh` atau `Rusak`. Jika `Rusak`, stok mutasi ke gudang tidak akan bertambah. `qty_butir` tetap diisi dengan jumlah butir telur terlepas dari kategorinya).*

---

### Transaksi Populasi Ayam (Kematian & Afkir)
Modul untuk mencatat laporan jumlah ayam yang mati atau diafkir dari suatu kandang.

- **GET** `/api/populasi/form?kdg_code={kdg_code}`
  - *Mengambil data kalkulasi populasi ayam saat ini (berdasar populasi awal di master dikurangi total riwayat kematian/afkir).*
  - **Contoh Response:**
  ```json
  {
      "status": "success",
      "data": {
          "prd_code": "PRD-2026-001",
          "kdg_code": "KDG-001",
          "populasi_awal_periode": 5000,
          "populasi_berkurang": 480,
          "populasi_sebelumnya": 4520
      }
  }
  ```
- **GET** `/api/populasi`
  - *Melihat daftar histori laporan kematian & afkir ayam.*
  - **Query Parameters (Opsional):** `kdg_code`, `start_date`, `end_date`.
- **POST** `/api/populasi`
  - *Mencatat kematian atau afkir ayam. Endpoint ini otomatis menambah stok gudang (Mutasi IN) untuk Ayam Mati (PRD-007) dan Ayam Afkir (PRD-008) dengan satuan Ekor.*
  - **Payload (JSON)**:
  ```json
  {
      "kdg_code": "KDG-001",
      "gudang_code": "GDG-001",
      "tanggal": "2026-08-25",
      "details": [
          {
              "sku_product": "PRD-007", 
              "kategori": "Mati",
              "qty_ekor": 5,
              "penyebab": "Penyakit ND",
              "catatan": "Ayam tiba-tiba mati lemas"
          },
          {
              "sku_product": "PRD-008", 
              "kategori": "Afkir",
              "qty_ekor": 2,
              "penyebab": "Tidak bertelur",
              "catatan": "Ayam sudah tua"
          }
      ]
  }
  ```

---

### Transaksi Checklist Kebersihan (Mobile Kandang)
Modul untuk memastikan Anak Kandang melakukan tugas kebersihan harian. Bukti wajib dikirim berupa file foto dari kamera HP yang memiliki *timestamp* asli.

- **GET** `/api/checklist?kdg_code={kdg_code}&tanggal={tanggal}`
  - *Mengambil daftar tugas kebersihan (digabung dari master kebersihan) beserta statusnya apakah sudah dikerjakan (Selesai) atau Belum hari ini.*
  - **Contoh Response:**
  ```json
  {
      "status": "success",
      "data": [
          {
              "chk_code": "CHK-KDG01-20260825-001",
              "kbrshn_code": "KBR-001",
              "kbrshn_nama": "Kebersihan Lantai",
              "kbrshn_desc": "Sapu dan buang sisa kotoran",
              "status": "Belum",
              "foto_bukti": null,
              "waktu_selesai": null
          }
      ]
  }
  ```
- **POST** `/api/checklist/submit`
  - *Menyimpan atau meng-update bukti foto dari satu item checklist. Anda wajib mengirim file foto (maks 5MB).*
  - **Tipe Payload**: `multipart/form-data`
  - **Parameter**:
    - `kdg_code` (Contoh: "KDG-001")
    - `kbrshn_code` (Contoh: "KBR-001")
    - `tanggal` (Contoh: "2026-08-25")
    - `foto_bukti` (File Upload, Tipe: JPG/JPEG/PNG)
