# Dokumentasi API Endog Racing Lengkap

Dokumen ini memuat spesifikasi lengkap dari seluruh *endpoint* API untuk kebutuhan integrasi Frontend (Web, Mobile Kandang, Mobile Sales) serta pengujian via **Postman**.

**Global Headers yang Wajib Disertakan:**
- `Accept: application/json`
- `Content-Type: application/json`
- `Authorization: Bearer {token}` *(Kecuali untuk endpoint Login)*

---

## 1. Modul Dashboard Admin (Web)

### 1. Dashboard Admin (Eksekutif & Inventory)

### 1.1 Dashboard Utama
Menarik metrik global atau spesifik per kandang, memantau *inventory*, serta data grafik. Hanya bisa diakses oleh *Role* `Owner` atau `Admin`.
- **URL**: `GET /api/admin/dashboard`
- **Query Parameter (Opsional)**:
  - `filter_waktu` = `hari_ini` (default), `minggu_ini`, `bulan_ini`.
  - `bulan` = `08` (Bulan spesifik, contoh: 08 untuk Agustus). Jika diisi bersama `tahun`, maka `filter_waktu` otomatis diabaikan.
  - `tahun` = `2026` (Tahun spesifik).
  - `kdg_code` = Filter spesifik untuk satu kandang (misal: `KDG-001`). Jika kosong, berarti seluruh kandang.
- **Response (200)**:
```json
{
  "status": "success",
  "data": {
    "filter_aktif": "minggu_ini",
    "kandang_aktif": "KDG-001",
    "metrics": {
      "populasi_ekor": 10500,
      "telur_utuh_kg": 500.5,
      "telur_rusak_kg": 15.2,
      "kematian_ekor": 10,
      "ayam_afkir_ekor": 5,
      "inventory_telur_kg": 1200,
      "inventory_pakan_kg": 5000,
      "inventory_obat_pcs": 250
    },
    "charts": {
      "tren_telur_kg": [
        {"tanggal": "2026-09-01", "total": 85},
        {"tanggal": "2026-09-02", "total": 90}
      ]
    }
  }
}
```
> **Info Sistem:**
> - `metrics.inventory_*` adalah stok riil di gudang saat ini (Mengabaikan `filter_waktu`).
> - `charts.tren_telur_kg` adalah array siap pakai untuk di-render oleh *library chart* (seperti Chart.js) selama 7 hari terakhir ke belakang (berdasarkan tanggal hari ini).

---

## 2. Authentication (Auth)

### 2.1 Login Web & Sales
- **URL**: `POST /api/login/web` (Web Admin) / `POST /api/login/sales` (Mobile Sales)
- **Auth Required**: No
- **Payload (JSON)**:
```json
{
  "usr_loginname": "admin_budi",
  "usr_password": "Password123!"
}
```
- **Response (200)**:
```json
{
  "message": "Login berhasil",
  "access_token": "1|xxxxxxxxxxxxxxx",
  "token_type": "Bearer",
  "user": {
    "id": 1,
    "usr_loginname": "admin_budi",
    "usr_rolecode": "Admin",
    "emp_code": "EMP-20260820001"
  }
}
```

### 1.2 Login Mobile Kandang (Kiosk Mode)
- **URL**: `POST /api/login/kandang`
- **Auth Required**: No
- **Prerequisite**: Gunakan `GET /api/kandang/list` untuk list kandang.
- **Payload (JSON)**:
```json
{
  "kdg_code": "KDG-001",
  "kdg_pin": "123456"
}
```
- **Response (200)**:
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

### 1.3 Verify Barcode Kandang
- **URL**: `POST /api/kandang/verify-barcode`
- **Payload (JSON)**:
```json
{
  "barcode": "BRC-KDG-001"
}
```
- **Response (200)**:
```json
{
  "status": "success",
  "data": {
    "kdg_code": "KDG-001",
    "kdg_nama": "Kandang Layer A"
  }
}
```

---

## 2. Transaksi Kandang (Mobile Kandang)

### 2.1 Dashboard Kandang
- **URL**: `GET /api/kandang/dashboard?filter=harian`
- **Response (200)**:
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

### 2.2 Pemakaian Pakan (Beri Makan Ayam)
- **List Form**: `GET /api/pemakaian-pakan/form?gudang_code=GDG-001`
- **Submit**: `POST /api/pemakaian-pakan`
- **Payload (JSON)**:
```json
{
    "gudang_code": "GDG-001",
    "kdg_code": "KDG-001",
    "tanggal": "2026-08-28",
    "details": [
        {
            "sku_product": "PKN-001",
            "qty_pakai": 50
        }
    ]
}
```
- **Response (201)**:
```json
{
    "status": "success",
    "message": "Pemakaian pakan berhasil dicatat dan stok gudang otomatis terpotong.",
    "data": {
        "pakai_code": "PKN-KDG-001-20260828-001",
        "status_approval": "Selesai"
    }
}
```

### 2.3 Pemakaian OVK (Obat, Vaksin, Kimia)
- **List Form**: `GET /api/pemakaian-ovk/form?gudang_code=GDG-001`
- **Submit**: `POST /api/pemakaian-ovk`
- **Payload (JSON)**:
```json
{
    "gudang_code": "GDG-001",
    "kdg_code": "KDG-001",
    "tanggal": "2026-08-30",
    "details": [
        {
            "sku_product": "OBT-001",
            "qty_pakai": 5
        },
        {
            "sku_product": "OBT-002",
            "qty_pakai": 10
        }
    ]
}
```
- **Response (201)**:
```json
{
    "status": "success",
    "message": "Pemakaian OVK berhasil dicatat, stok memotong gudang dan jurnal akuntansi telah terbentuk.",
    "data": {
        "pakai_code": "OVK-KDG-001-20260830-001",
        "total_biaya": 150000
    }
}
```

### 2.4 Produksi Telur (Panen)
- **List Form**: `GET /api/produksi-telur/form?kdg_code=KDG-001`
- **Submit**: `POST /api/produksi-telur`
- **Payload (JSON)**:
```json
{
    "kdg_code": "KDG-001",
    "gudang_code": "GDG-001",
    "tanggal": "2026-08-28",
    "details": [
        {
            "sku_product": "TLR-001",
            "kategori": "Utuh",
            "qty_butir": 1000,
            "qty_kg": 60.5
        }
    ]
}
```
- **Response (201)**:
```json
{
    "status": "success",
    "message": "Produksi telur berhasil disimpan",
    "data": {
        "prd_code": "PRD-20260828-001"
    }
}
```


### 2.5 Kematian & Afkir Ayam (Populasi)
- **List Form**: `GET /api/populasi/form?kdg_code=KDG-001`
  - **Response (200)**:
  ```json
  {
      "status": "success",
      "data": {
          "populasi_sebelumnya": 5500,
          "list_penyakit": [
              {
                  "penyakit_code": "PYK-001",
                  "penyakit_nama": "ND (Tetelo)",
                  "penyakit_kategori": "Virus"
              }
          ]
      }
  }
  ```
- **Submit**: `POST /api/populasi`
- **Payload (JSON)**:
```json
{
    "kdg_code": "KDG-001",
    "gudang_code": "GDG-001",
    "tanggal": "2026-08-28",
    "details": [
        {
            "sku_product": "PRD-007", 
            "kategori": "Mati",
            "qty_ekor": 5,
            "penyebab": null,
            "penyebab_lainnya": "Terjepit",
            "catatan": "Ayam mati mendadak di pojok kandang"
        }
    ]
}
```
- **Catatan Parameter Kategori Mati**: 
  - Jika ayam mati karena penyakit terdaftar, isi `penyebab` dengan kode penyakit (Contoh: `PYK-001`) dan biarkan `penyebab_lainnya` kosong.
  - Jika ayam mati karena sebab lain di luar penyakit (Misal: Terjepit), isi `penyebab` dengan `null`, lalu isi `penyebab_lainnya` dengan teks ketikan manual, dan tambahkan `catatan` jika perlu.
- **Response (201)**:
```json
{
    "status": "success",
    "message": "Laporan populasi ayam berhasil disimpan dan data gudang terupdate."
}
```
> **Info Target Tabel**: Payload dengan kategori `Mati` akan tersimpan di tabel `edg_tr_kematian_ayam`, sedangkan kategori `Afkir` akan tersimpan di `edg_tr_afkir_ayam` dan men-*trigger* mutasi Gudang masuk (karena bangkai/afkiran jual).

### 2.6 Checklist Kebersihan
- **List Tugas**: `GET /api/checklist?kdg_code=KDG-001&tanggal=2026-08-28`
- **Submit (Upload File)**: `POST /api/checklist/submit`
  - **Headers**: Biarkan otomatis `multipart/form-data`.
  - **Body (form-data)**: `kdg_code` (Text), `kbrshn_code` (Text), `tanggal` (Text), `foto_bukti` (File Image)
- **Response (200)**:
```json
{
    "status": "success",
    "message": "Checklist berhasil disimpan"
}
```

---

## 3. Transaksi Sales (Mobile Sales)

### 3.1 Form Penjualan Telur
- **Endpoint**: `GET /api/penjualan/form`
- **Response (200)**: Menampilkan list kustomer dan stok barang di mobil beserta harga yang sudah di-*lock* oleh pusat (Harga Dasar + Margin Sales).
```json
{
    "status": "success",
    "message": "Berhasil mengambil data form penjualan",
    "data": {
        "customers": [
            { "customer_code": "CST-001", "customer_name": "Toko Barokah" }
        ],
        "products": [
            {
                "sku_product": "TLR-001",
                "sku_name": "Telur Layer (Utuh)",
                "stock_tersedia": 150,
                "harga_dasar_cogs": 24000,
                "margin_sales": 2000,
                "harga_jual_final": 26000,
                "qty_jual": 0
            }
        ]
    }
}
```
> **Info Sistem:** Frontend **WAJIB** mengunci (Read-Only) inputan harga jual (PRICE/KG) di layar menggunakan angka dari `harga_jual_final`.

### 3.2 Submit Transaksi Penjualan Telur
- **Endpoint**: `POST /api/penjualan`
- **Payload**:
```json
{
  "customer_name": "Toko Sejahtera",
  "gudang_code": "GDG-002",
  "tanggal": "2024-02-15",
    "metode_bayar": "Tunai",
    "details_jual": [
        {
            "sku_product": "TLR-001",
            "qty": 100,
            "harga_jual": 26000
        }
    ],
    "details_retur": [
        {
            "sku_product": "TLR-001",
            "qty": 5,
            "harga_kompensasi": 20000,
            "keterangan": "Pecah di jalan"
        }
    ]
}
```
> **Info Sistem:** Payload ini sudah mendukung Auto-Create Customer. Frontend tidak perlu memanggil GET /api/master/customer. Cukup kirimkan nama pelanggan di `customer_name`. Jika belum terdaftar, sistem akan otomatis mendaftarkan pelanggan tersebut. Selain itu, sistem sudah mendukung **Retur Tukar Guling**. Jika sales membawa telur retur dari kustomer, masukkan di `details_retur`. Sistem akan mengurangi stok telur bagus di mobil (Mutasi Out) dan menambah stok telur rusak di Gudang Retur (Mutasi In), lalu tagihan bersih (*Grand Total*) otomatis dikurangi kompensasi retur.
- **Response (201)**:
```json
{
    "status": "success",
    "message": "Penjualan berhasil dicatat",
    "data": {
        "jual_code": "JUAL-20260828-001",
        "total_bayar": 262500
    }
}
```
- **Response Error Manipulasi Harga (400 Bad Request)**:
```json
{
  "status": "error",
  "message": "Harga jual untuk TLR-001 (Rp 23.000) tidak valid! Harga harus sesuai ketentuan sistem (Rp 26.000)."
}
```

### 3.3 List Histori Penjualan
- **Endpoint**: `GET /api/penjualan`
- **Response (200)**: Menampilkan list histori transaksi penjualan beserta status pembayaran (`Paid`, `Unpaid`, `Parsial`).

### 3.3 Terima Pembayaran Piutang (Cicilan)
- **Endpoint**: `POST /api/penjualan/bayar-piutang`
- **Payload (JSON)**:
```json
{
  "jual_code": "INV/202609/0001",
  "nominal_bayar": 500000,
  "metode_bayar": "Tunai",
  "catatan": "Cicilan Pertama"
}
```

### 3.4 Absensi Sales Harian
- **Endpoint**: `POST /api/sales/absensi`
- **Payload (JSON)**:
```json
{
  "tipe_absen": "Masuk", 
  "latitude": -6.123,
  "longitude": 106.123,
  "foto_selfie": "(Base64 / File)"
}
```

### 3.5 Top Up Deposit Kustomer
- **Top Up Saldo**: `POST /api/deposit/topup`
- **Payload (JSON)**:
```json
{
    "customer_code": "CUST-08FE3A",
    "customer_name": "Toko Sejahtera",
    "tanggal": "2024-02-15",
    "nominal": 1000000,
    "metode_bayar": "Transfer Bank"
}
```
- **Response (201)**:
```json
{
    "status": "success",
    "message": "Top up deposit berhasil",
    "data": {
        "deposit_code": "DEP-20260828-001"
    }
}
```

### 3.3 Penarikan Telur oleh Sales (Deposit Barang / Konsinyasi)
Endpoint ini digunakan ketika Sales mengambil telur dari Gudang Utama untuk dijual keliling, namun belum laku/diserahkan ke Kustomer akhir.
- **Submit Penarikan**: `POST /api/sales/deposit-barang`
- **Payload (JSON)**:
```json
{
    "emp_code": "EMP-001",
    "gudang_code": "GDG-001",
    "tanggal": "2026-08-28",
    "details": [
        {
            "sku_product": "TLR-001",
            "qty": 50
        }
    ]
}
```
> **Info Akuntansi (Skenario A):** Transaksi ini tidak mencetak Jurnal Pendapatan. Transaksi ini hanya mencatat Mutasi Out dari *Gudang Utama* dan Mutasi In ke *Gudang Mobil Sales*, serta menjurnal perpindahan harta: **Debit: Persediaan di Tangan Sales** dan **Kredit: Persediaan Produk**.

---

## 4. Transaksi & Approval

### 4.1 Purchase Order (PO) Pembelian Barang
- **Create PO**: `POST /api/pembelian`
- **Payload (JSON)**:
```json
{
    "supplier_code": "SUP-001",
    "gudang_code": "GDG-001",
    "tanggal": "2026-08-28",
    "details": [
        {
            "sku_product": "PKN-001",
            "qty": 50
        },
        {
            "sku_product": "OBT-001",
            "qty": 10
        }
    ]
}
```
- **Response (201)**:
```json
{
    "status": "success",
    "message": "Purchase Order berhasil dibuat",
    "data": {
        "po_h": "PO-20260828-001"
    }
}
```

- **Approve PO**: `POST /api/pembelian/PO-20260828-001/approve`
- **Response (200)**:
```json
{
    "status": "success",
    "message": "PO Berhasil disetujui, Stok bertambah, dan Jurnal Akuntansi telah dicatat"
}
```
> **Catatan Jurnal Otomatis:** Saat di-*approve*, sistem akan mengecek *Kategori Produk* (misal: Pakan, Obat, Vitamin) dari masing-masing barang di dalam PO. Sistem kemudian akan memecah Jurnal Debit berdasarkan COA masing-masing (contoh: Debit ke `Pembelian Pakan` dan `Pembelian Obat` secara terpisah dalam 1 transaksi PO), lalu dikreditkan ke Akun Bank (Metode Transfer wajib sesuai SOP).

### 4.2 Penerimaan Barang (Tanda Terima - Blind Receiving)
- **Terima Barang Baru**: `POST /api/penerimaan-barang` (Bisa `multipart/form-data` jika unggah foto surat jalan)
- **Payload (JSON / Form-Data)**:
```json
{
    "po_h": "PO-20260828-001",
    "tanggal_terima": "2026-08-29",
    "penerima_name": "Pak Budi Gudang",
    "no_surat_jalan": "SJ/KIMIAFARMA/099",
    "foto_surat_jalan": "[File]",
    "details": [
        {
            "sku_product": "PKN-001",
            "qty_terima": 50
        }
    ]
}
```
> **Catatan Blind Receiving**: Qty PO dari *supplier* tidak divalidasi. Staf gudang murni memasukkan *qty_terima* fisik aktual. API akan me-return **Nomor PB** (`terima_code`) secara otomatis yang BERBEDA dari Nomor PO dan Surat Jalan.
- **Response (201)**:
```json
{
    "status": "success",
    "message": "Penerimaan Barang berhasil dicatat"
}
```


### 4.4 Inventory Stok & Mutasi
- **Cek Saldo Stok**: `GET /api/inventory/stok?gudang_code=GDG-001&kdg_code=KDG-001&sku_product=PRD-005`
- **Cek Histori Mutasi**: `GET /api/inventory/mutasi?gudang_code=GDG-001&kdg_code=KDG-001&start_date=2026-08-01&end_date=2026-08-31`
> **Catatan Filter**: 
> Parameter `gudang_code` dan `kdg_code` bersifat opsional. 
> Jika Anda mengirimkan `kdg_code`, API akan menampilkan stok / histori mutasi yang KHUSUS milik Kandang tersebut (Sangat berguna untuk laporan profitabilitas & beban per kandang).

- **Response (200)**:
```json
{
    "status": "success",
    "message": "Berhasil mengambil data",
    "data": [
        {
            "gudang_code": "GDG-001",
            "sku_product": "PKN-001",
            "sku_name": "Pakan Starter",
            "stock_akhir": 50.0
        }
    ]
}
```

---

## 5. Master Data (Web Admin)

Standar *RESTful API* untuk data Master (`/api/master/*`). Response standarnya adalah:
```json
{
    "status": "success",
    "data": { ... } 
}
```

### 5.1 Pegawai & Akun (`/api/master/users`)
- **Mendapatkan List Pegawai**: `GET /api/master/users`
- **Mendapatkan Detail Pegawai**: `GET /api/master/users/{emp_code}`
- **Menambah Pegawai Baru**: `POST /api/master/users`
```json
{
  "emp_code": "EMP-004",
  "emp_name": "Agus Santoso",
  "emp_jabatan": "Mandor",
  "emp_telp": "08123456789",
  "emp_alamat": "Jl. Peternakan",
  "usr_loginname": "mandor_agus",
  "usr_password": "Password123!",
  "usr_rolecode": "Kandang",
  "usr_status": "Aktif"
}
```
*(Catatan: `emp_code` bersifat opsional. Jika tidak dikirim, backend akan otomatis membuatkannya dengan format `EMP-XXX`)*

- **Mengupdate Pegawai**: `PUT /api/master/users/{emp_code}`
```json
{
  "emp_name": "Agus Santoso Revisi",
  "usr_status": "Nonaktif"
}
```
*(Catatan: Hanya properti yang dikirim yang akan diupdate)*

- **Menghapus Pegawai**: `DELETE /api/master/users/{emp_code}`

### 5.2 Kandang (`POST /api/master/kandang`)
```json
{
    "kdg_code": "KDG-001",
    "kdg_nama": "Kandang Layer A",
    "kdg_kapasitas": 5000,
    "kdg_alamat": "Blok A",
    "kdg_pin": "123456"
}
```

### 5.3 Gudang (`POST /api/master/gudang`)
```json
{
    "gudang_code": "GDG-001",
    "gudang_nama": "Gudang Pakan Pusat",
    "gudang_tipe": "Pakan",
    "kdg_code": "KDG-001"
}
```

### 5.4 Produk & Barang (`POST /api/master/product-business`)
```json
{
    "sku_product": "PKN-001",
    "sku_name": "Pakan Starter 50KG",
    "sku_category": "Pakan",
    "sku_uom": "KG"
}
```

### 5.5 Pelanggan (`POST /api/master/customer`)
```json
{
    "customer_code": "CST-001",
    "customer_name": "Toko Barokah",
    "customer_phone": "08199988877",
    "customer_tipe": "Agen"
}
```

### 5.6 Supplier (`POST /api/master/supplier`)
```json
{
    "supplier_code": "SUP-001",
    "supplier_name": "PT Pakan Ternak",
    "supplier_phone": "021-123456"
}
```

### 5.7 COA Dasar & Filter Tipe
- **Mendapatkan List COA**: `GET /api/master/coa`
  - *(Gunakan `?type=EXPENSE` atau `?type=KAS_BANK` untuk filter dropdown).*
- **Membuat COA Baru**: `POST /api/master/coa`
```json
{
    "coa_code": "101",
    "coa_nama": "Kas Bank",
    "coa_tipe": "Asset"
}
```

### 5.8 HPP Pakan / COGS
- **Mendapatkan HPP**: `GET /api/master/cogs`
- **Set HPP Baru**: `POST /api/master/cogs`
```json
{
    "sku_product": "PKN-001",
    "cogs_price": 7500,
    "cogs_effective_date": "2026-08-01"
}
```

### 5.9 Setting COA Otomatis
Digunakan untuk mengarahkan alur jurnal otomatis sistem.
- **Melihat Setting COA**: `GET /api/master/setting-coa`
- **Membuat Setting COA Baru**: `POST /api/master/setting-coa`
```json
{
    "type_coa": "Pemakaian Listrik Kandang",
    "gudang_code": "GDG-001",
    "coa_code": "6200"
}
```
- **Update Setting COA**: `PUT /api/master/setting-coa/{setting_code}`
```json
{
    "type_coa": "Pembelian Pakan",
    "gudang_code": "GDG-001",
    "coa_code": "103"
}
```
- **Hapus Setting COA**: `DELETE /api/master/setting-coa/{setting_code}`

---

## 6. Keuangan & Operasional Khusus (Web Admin)

### 6.1 Buku Kas Dasar (Arus Kas)
Endpoint ini digunakan untuk melihat mutasi kas atau melakukan pencatatan transaksi kas manual (terutama transfer antar kas/bank, setoran modal awal, atau tarik tunai). Transaksi yang diinput akan otomatis terbentuk Jurnal Akuntansinya.

- **Get Riwayat Kas (Laporan Arus Kas)**: `GET /api/buku-kas?kas_bank_code=KB-001`
- **Catat Transaksi Manual (IN/OUT/TRANSFER)**: `POST /api/buku-kas`

**Payload (JSON) - Tipe IN (Uang Masuk / Modal)**:
```json
{
    "kas_bank_code": "KB-001",
    "tipe_transaksi": "IN",
    "nominal": 5000000,
    "tanggal": "2026-08-28",
    "coa_code_lawan": "106", 
    "keterangan": "Suntikan Modal Awal / Pendapatan Lain"
}
```
*(Catatan: `coa_code_lawan` wajib diisi untuk IN dan OUT agar sistem tahu lawan jurnal dari penambahan kas tersebut).*

**Payload (JSON) - Tipe TRANSFER (Pindah Dana)**:
```json
{
    "kas_bank_code": "KB-001",
    "tipe_transaksi": "TRANSFER",
    "kas_bank_tujuan": "KB-002",
    "nominal": 1500000,
    "tanggal": "2026-08-28",
    "keterangan": "Pemindahan dana dari Bank BCA ke Laci Kasir Kecil"
}
```

**Response (201)**:
```json
{
    "status": "success",
    "message": "Transaksi kas berhasil dicatat dan dijurnal.",
    "data": {
        "transaksi_code": "KAS-20260828-001",
        "kas_bank_code": "KB-001",
        "tipe_transaksi": "TRANSFER",
        "kas_bank_tujuan": "KB-002",
        "nominal": 1500000,
        "keterangan": "Pemindahan dana dari Bank BCA ke Laci Kasir Kecil",
        "tanggal": "2026-08-28"
    }
}
```

### 6.2 Pengeluaran Biaya Operasional (Bensin, Listrik, dll)
Endpoint ini khusus untuk pengeluaran *Overhead* yang langsung diakui sebagai biaya perusahaan, di mana pembayarannya diambil dari Kas/Bank tertentu.

- **Daftar Biaya Operasional**: `GET /api/biaya-operasional?start_date=2026-08-01&end_date=2026-08-31`
- **Catat Biaya Operasional**: `POST /api/biaya-operasional`
- **Payload (JSON)**:
```json
{
    "coa_code": "110",
    "kas_bank_code": "KB-001",
    "nominal": 50000,
    "tanggal": "2026-08-28",
    "keterangan": "Beli Bensin Genset Kandang A"
}
```
*(Catatan: `coa_code` wajib menggunakan kode COA yang tipenya Expense/Biaya, misal 110 untuk Biaya Listrik, Air, & Bensin).*

**Response (201)**:
```json
{
    "status": "success",
    "message": "Biaya operasional berhasil dicatat.",
    "data": {
        "expense_code": "OPR-20260828-001",
        "coa_code": "110",
        "kas_bank_code": "KB-001",
        "tanggal": "2026-08-28",
        "nominal": 50000,
        "keterangan": "Beli Bensin Genset Kandang A"
    }
}
```

### 6.3 System Logs (Audit Trail)
Merekam semua aktivitas *User* (Create, Update, Delete) secara diam-diam. Endpoint ini digunakan oleh Admin / Auditor untuk melihat jejak rekam aplikasi.

- **Cek Histori**: `GET /api/system-logs?module=PEMBELIAN`
- **Response (200)**:
```json
{
    "status": "success",
    "data": {
        "current_page": 1,
        "data": [
            {
                "id": 1,
                "usr_loginname": "admin_budi",
                "action": "POST",
                "module": "PEMBELIAN",
                "description": "User performed POST on PEMBELIAN. Target ID: PO-20260828-001.",
                "ip_address": "192.168.1.15",
                "created_at": "2026-08-28 21:00:00"
            }
        ]
    }
}
```

### 6.4 Modul Penggajian (HR & Payroll)
Modul ini digunakan untuk mendata slip gaji karyawan, memotong uang dari Kas/Bank, serta otomatis mencetak jurnal akuntansi (Beban Gaji & Potongan).

- **Daftar Histori Penggajian**: `GET /api/penggajian?emp_code=EMP-001&periode_bulan=8&periode_tahun=2026`
- **Catat Slip Gaji Baru**: `POST /api/penggajian`
- **Payload (JSON)**:
```json
{
    "emp_code": "EMP-001",
    "kas_bank_code": "KB-001",
    "periode_bulan": 8,
    "periode_tahun": 2026,
    "gaji_pokok": 5000000,
    "details": [
        {
            "jenis_komponen": "BONUS",
            "nama_komponen": "Uang Makan",
            "nominal": 300000
        },
        {
            "jenis_komponen": "POTONGAN",
            "nama_komponen": "Kasbon",
            "nominal": 150000
        }
    ]
}
```
*(Catatan: `total_gaji` akan dihitung otomatis oleh sistem sebagai Gaji Pokok + Bonus - Potongan).*

**Response (201)**:
```json
{
    "status": "success",
    "message": "Penggajian berhasil dicatat",
    "data": {
        "gaji_code": "GAJI-202608-001",
        "emp_code": "EMP-001",
        "kas_bank_code": "KB-001",
        "periode_bulan": 8,
        "periode_tahun": 2026,
        "gaji_pokok": 5000000,
        "total_bonus": 300000,
        "total_potongan": 150000,
        "total_gaji": 5150000
    }
}
```
