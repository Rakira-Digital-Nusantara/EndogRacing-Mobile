# Dokumentasi API Mobile Sales — Endog Racing

> **Semua request butuh header `Authorization: Bearer {token}` (kecuali endpoint login).**  
> Base URL: `https://yourdomain.com/api`

---

## 0. Autentikasi

### Login Sales
**`POST /api/login/sales`**

Gunakan ini untuk mendapatkan Bearer Token. Token ini **wajib** disertakan di semua request selanjutnya.

**Body Request (JSON):**
```json
{
    "usr_loginname": "sales1",
    "usr_password": "password123"
}
```

**Response Sukses:**
```json
{
    "status": "success",
    "data": {
        "token": "1|abc123XYZlong...",
        "user": {
            "usr_loginname": "sales1",
            "usr_rolecode": "Sales",
            "emp_code": "EMP-001",
            "margin_sales": 500
        }
    }
}
```

> 💡 Setelah login, **segera kirim FCM Token** ke `POST /api/fcm-token` agar Push Notification bisa bekerja.

---

## 1. Dashboard Sales

### `GET /api/sales/dashboard`

Ambil ringkasan performa hari ini: stok mobil, stok pusat, total KG terjual, piutang, dan absensi.

**Query Params:**

| Param | Tipe | Keterangan |
|---|---|---|
| `tanggal` | string | Opsional. Format `YYYY-MM-DD`. Default: hari ini. |

**Response Sukses:**
```json
{
    "status": "success",
    "data": {
        "harga_sentral": 27000.0,
        "list_harga_hari_ini": [
            { "sku_name": "Telur Utuh", "harga": 27000.0 }
        ],
        "stok_mobil": 150.0,
        "stok_mobil_kas": 10.0,
        "stok_pusat": 2500.0,
        "stok_pusat_kas": 166.0,
        "total_kg_terjual": 50.0,
        "total_kas_terjual": 3.0,
        "rincian_stok_mobil": [
            {
                "sku_product": "TLR-001",
                "sku_name": "Telur Utuh",
                "harga_sentral": 27000.0,
                "qty_kg": 150.0,
                "qty_kas": 10
            }
        ],
        "rincian_stok_pusat": [
            {
                "sku_product": "TLR-001",
                "sku_name": "Telur Utuh",
                "harga_sentral": 27000.0,
                "qty_kg": 2500.0,
                "qty_kas": 166
            }
        ],
        "total_cash_paid": 1350000.0,
        "total_piutang": 500000.0,
        "list_unpaid": [
            {
                "jual_code": "INV/202609/0001",
                "customer_name": "Toko Berkah",
                "sisa_piutang": 500000.0,
                "tanggal": "2026-09-12"
            }
        ],
        "absensi": {
            "sudah_masuk": true,
            "sudah_pulang": false
        }
    }
}
```

> **Catatan penting field stok:**  
> - `stok_mobil` = total KG di gudang mobil Sales yang sedang login  
> - `stok_mobil_kas` = konversi KAS (1 KAS = 15 KG, sesuai setting master produk)  
> - `list_unpaid` = semua piutang yang belum lunas milik Sales ini (lintas hari)

---

## 2. Form Penjualan

### `GET /api/penjualan/form`

Ambil data yang diperlukan untuk mengisi form penjualan: daftar customer, daftar produk + stok + harga.

**Response:**
```json
{
    "status": "success",
    "data": {
        "customers": [
            { "customer_code": "CUST-001", "customer_name": "Toko Berkah Makmur" }
        ],
        "products": [
            {
                "sku_product": "TLR-001",
                "sku_name": "Telur Utuh",
                "sku_uom": "Kg",
                "stock_tersedia": 150.0,
                "harga_dasar_cogs": 27000.0,
                "margin_sales": 500.0,
                "harga_jual_final": 27500.0,
                "qty_jual": 0
            }
        ],
        "gudang_telur_code": "GDG-004",
        "metode_bayar_options": ["Tunai", "Deposit", "Tempo"]
    }
}
```

---

## 3. Penjualan Telur

### A. Buat Penjualan Baru
**`POST /api/penjualan`**  
**Content-Type: `application/json`**

**Field Penting:**

| Field | Wajib | Tipe | Keterangan |
|---|---|---|---|
| `customer_code` | Ya | string | Kode customer dari daftar. |
| `tanggal` | Ya | string | Format `YYYY-MM-DD`. |
| `opsi_bayar` | Ya | string | **`Lunas`**, **`Sebagian`**, atau **`Belum Bayar`** |
| `nominal_dibayar` | Jika `Sebagian` | numeric | Jumlah yang dibayar sekarang. |
| `tgl_jatuh_tempo` | Jika `Sebagian`/`Belum Bayar` | string | Tanggal jatuh tempo piutang `YYYY-MM-DD`. |
| `details` | Ya | array | Daftar item penjualan. |
| `details.*.sku_product` | Ya | string | Kode SKU produk. |
| `details.*.qty` | Ya | numeric | Jumlah dalam KG. |
| `details.*.harga_satuan` | Opsional | numeric | Harga/kg. Jika dikosongkan, sistem pakai COGS + margin. |
| `details_retur` | Opsional | array | Jika ada telur rusak yang dikembalikan (tukar guling). |
| `details_retur.*.sku_product` | Ya (jika retur) | string | SKU produk yang diretur. |
| `details_retur.*.qty` | Ya (jika retur) | numeric | Jumlah KG yang diretur. |
| `details_retur.*.harga_kompensasi` | Ya (jika retur) | numeric | Kompensasi harga per KG untuk retur. |

**Contoh Payload (Penjualan LUNAS):**
```json
{
    "customer_code": "CUST-20260909-001",
    "tanggal": "2026-09-12",
    "opsi_bayar": "Lunas",
    "details": [
        { "sku_product": "TLR-001", "qty": 30, "harga_satuan": 27500 }
    ]
}
```

**Contoh Payload (Bayar SEBAGIAN / Cicil):**
```json
{
    "customer_code": "CUST-001",
    "tanggal": "2026-09-12",
    "opsi_bayar": "Sebagian",
    "nominal_dibayar": 300000,
    "tgl_jatuh_tempo": "2026-09-19",
    "details": [
        { "sku_product": "TLR-001", "qty": 30, "harga_satuan": 27500 }
    ]
}
```

**Contoh Payload (BELUM BAYAR / Piutang Penuh):**
```json
{
    "customer_code": "CUST-001",
    "tanggal": "2026-09-12",
    "opsi_bayar": "Belum Bayar",
    "tgl_jatuh_tempo": "2026-09-19",
    "details": [
        { "sku_product": "TLR-001", "qty": 30, "harga_satuan": 27500 }
    ]
}
```

**Contoh Payload (Penjualan + Retur Tukar Guling bersamaan):**
```json
{
    "customer_code": "CUST-001",
    "tanggal": "2026-09-12",
    "opsi_bayar": "Lunas",
    "details": [
        { "sku_product": "TLR-001", "qty": 30, "harga_satuan": 27500 }
    ],
    "details_retur": [
        { "sku_product": "TLR-RSK-001", "qty": 2, "harga_kompensasi": 10000 }
    ]
}
```

**Response Sukses (201):**
```json
{
    "status": "success",
    "message": "Penjualan berhasil dicatat dan stok telur telah dikurangi.",
    "data": {
        "jual_code": "INV/202609/0001",
        "tanggal": "2026-09-12",
        "customer_code": "CUST-001",
        "total_akhir": 825000,
        "total_dibayar": 825000,
        "sisa_piutang": 0,
        "status_bayar": "Paid",
        "details": [...]
    }
}
```

> **`status_bayar`** akan otomatis dihitung:
> - `Paid` → jika `opsi_bayar = Lunas` atau `nominal_dibayar >= total`
> - `Parsial` → jika `opsi_bayar = Sebagian`
> - `Unpaid` → jika `opsi_bayar = Belum Bayar`

---

### B. Daftar Histori Penjualan Sales
**`GET /api/penjualan`**

Menampilkan seluruh histori penjualan milik Sales yang sedang login.

**Query Params (Opsional):**

| Param | Tipe | Keterangan |
|---|---|---|
| `start_date` | string | Filter dari tanggal (YYYY-MM-DD) |
| `end_date` | string | Filter sampai tanggal (YYYY-MM-DD) |
| `status_bayar` | string | Filter `Paid` / `Parsial` / `Unpaid` |

---

### C. Terima Cicilan Piutang (Per Invoice)
**`POST /api/penjualan/bayar-piutang`**  
**Content-Type: `application/json`**

Digunakan saat Sales menerima pembayaran dari customer untuk 1 invoice spesifik.

```json
{
    "jual_code": "INV/202609/0001",
    "nominal_bayar": 300000,
    "metode_bayar": "Tunai",
    "catatan": "Bayar cicilan pertama"
}
```

> `metode_bayar`: `"Tunai"` / `"Deposit"` / `"Transfer"`

---

## 4. Rekap & Laporan

### A. Rekap Penjualan Harian
**`GET /api/sales/rekap-harian`**

Tampilkan total penjualan hari ini beserta rincian per toko.

**Query Params:**

| Param | Tipe | Keterangan |
|---|---|---|
| `tanggal` | string | Opsional. Format `YYYY-MM-DD`. Default: hari ini. |

**Response:**
```json
{
    "status": "success",
    "data": {
        "tanggal": "2026-09-12",
        "total_omset": 825000.0,
        "total_lunas": 825000.0,
        "total_piutang": 0.0,
        "total_telur_kg": 30.0,
        "total_telur_kas": 2.0,
        "rincian_toko": [
            {
                "nama_toko": "Toko Berkah",
                "jumlah_transaksi": 2,
                "total_belanja": 550000.0,
                "status_list": ["Paid", "Parsial"],
                "qty_telur_kg": 20.0
            }
        ]
    }
}
```

---

### B. Rekap Bulanan (Tampilan Akun)
**`GET /api/sales/rekap-bulanan`**

Tampilan rekap statistik penjualan Sales dalam satu bulan.

**Query Params:**

| Param | Tipe | Keterangan |
|---|---|---|
| `bulan` | integer | Nomor bulan (1-12). Default: bulan ini. |
| `tahun` | integer | Tahun (YYYY). Default: tahun ini. |

**Response:**
```json
{
    "status": "success",
    "data": {
        "periode": "2026-09",
        "total_omset_bulanan": 8250000.0,
        "total_lunas_bulanan": 7500000.0,
        "total_piutang_bulanan": 750000.0,
        "jumlah_transaksi_bulanan": 45
    }
}
```

---

## 5. Setoran Uang ke Kas

### A. Riwayat Setoran
**`GET /api/sales/riwayat-setoran`**

**Query Params (Opsional):**

| Param | Tipe | Keterangan |
|---|---|---|
| `tanggal` | string | Filter per tanggal `YYYY-MM-DD`. |

**Response:**
```json
{
    "status": "success",
    "data": {
        "total_setoran_semua": 3000000.0,
        "jumlah_transaksi_setoran": 3,
        "history": [
            {
                "setoran_code": "STR/202609/0001",
                "tanggal": "2026-09-12",
                "waktu": "15:30:00",
                "nominal_setoran": 1000000.0,
                "status_setoran": "Berhasil",
                "catatan": "Setoran sore",
                "foto_bukti": "https://yourdomain.com/storage/setoran/foto.jpg"
            }
        ]
    }
}
```

---

### B. Setor Uang ke Kas Besar
**`POST /api/sales/setor`**  
**Content-Type: `multipart/form-data`**

Digunakan saat Sales menyetorkan uang fisik hasil penjualan ke Kas Besar.

| Field | Tipe | Wajib | Keterangan |
|---|---|---|---|
| `emp_code` | string | Ya | Kode karyawan Sales. |
| `kas_bank_tujuan` | string | Ya | Kode COA tujuan (tanya Admin untuk kode yang benar). |
| `tanggal` | string | Ya | Format `YYYY-MM-DD`. |
| `total_setoran` | numeric | Ya | Total uang yang disetor (harus sama dengan jumlah detail). |
| `foto_bukti` | file (image) | Opsional | Foto bukti setor (JPG/PNG, maks 5MB). |
| `details` | array (JSON) | Ya | Rincian invoice yang dibayarkan. |
| `details[0][jual_code]` | string | Ya | Kode nota penjualan. |
| `details[0][nominal_bayar]` | numeric | Ya | Nominal yang dibayar untuk nota ini. |

> ⚠️ `total_setoran` **HARUS sama persis** dengan total penjumlahan `nominal_bayar` di semua details.

**Contoh Payload (form-data):**
```
emp_code        = EMP-001
kas_bank_tujuan = 1100
tanggal         = 2026-09-12
total_setoran   = 825000
foto_bukti      = [file]
details[0][jual_code]     = INV/202609/0001
details[0][nominal_bayar] = 825000
```

**Response Sukses (201):**
```json
{
    "status": "success",
    "message": "Setoran berhasil dicatat.",
    "data": {
        "setor_code": "STR/202609/0001",
        "tanggal": "2026-09-12",
        "total_setoran": 825000,
        "details": [...]
    }
}
```

---

### C. Setor Khusus dari Customer (Deposit Customer)
**`POST /api/sales/setor-customer`**  
**Content-Type: `multipart/form-data`**

Digunakan saat customer membayar piutang langsung ke Sales (tanpa mengaitkan ke nota tertentu dulu).

| Field | Tipe | Keterangan |
|---|---|---|
| `customer_code` | string | Kode pelanggan. |
| `nominal` | numeric | Jumlah yang diterima dari customer. |
| `tanggal` | string | Format `YYYY-MM-DD`. |
| `foto_bukti` | file (image) | Opsional, foto bukti uang/transfer. |

---

## 6. Saldo Uang di Tangan Sales

### `GET /api/sales/saldo-di-tangan`

Lihat total uang yang ada di tangan Sales (penjualan sudah terjadi tapi belum disetor ke Kas).

**Response:**
```json
{
    "status": "success",
    "data": {
        "total_penjualan_cash": 2700000.0,
        "total_sudah_disetor": 1500000.0,
        "saldo_belum_disetor": 1200000.0
    }
}
```

---

## 7. Absensi Sales

### `POST /api/sales/absensi`
**Content-Type: `multipart/form-data`**

| Field | Tipe | Wajib | Keterangan |
|---|---|---|---|
| `tipe_absen` | string | Ya | **`Masuk`** atau **`Pulang`** |
| `latitude` | numeric | Ya | Koordinat GPS. |
| `longitude` | numeric | Ya | Koordinat GPS. |
| `foto_absensi` | file (image) | Ya | Foto selfie wajib disertakan. |

**Response:**
```json
{
    "status": "success",
    "message": "Absensi berhasil dicatat",
    "data": { "emp_code": "EMP-001", "tipe_absen": "Masuk", "tanggal": "2026-09-12" }
}
```

> ⚠️ Key foto adalah **`foto_absensi`**. Harus dikirim sebagai `multipart/form-data`, bukan JSON.

---

## 8. Ambil Barang / Deposit Ke Mobil

### A. Form Ambil Barang (Data Stok & Produk)
**`GET /api/sales/tarik-barang/form`**

**Query Params:**

| Param | Keterangan |
|---|---|
| `gudang_asal` | Opsional. Kode gudang asal. Default: gudang pusat pertama. |

**Response:**
```json
{
    "status": "success",
    "gudang_asal": [
        { "gudang_code": "GDG-001", "gudang_nama": "Gudang Pusat" }
    ],
    "gudang_tujuan": {
        "gudang_code": "GDG-M01",
        "gudang_nama": "Gudang Mobil Sales 1"
    },
    "produk": [
        {
            "sku_product": "TLR-001",
            "sku_name": "Telur Utuh",
            "stok_tersedia_kg": 2500.0,
            "stok_tersedia_kas": 166,
            "konversi_label": "1 KAS = 15 Kg"
        }
    ]
}
```

---

### B. Ambil Barang dari Gudang ke Mobil
**`POST /api/sales/deposit-barang`**  
**Content-Type: `application/json`**

| Field | Wajib | Keterangan |
|---|---|---|
| `emp_code` | Ya | Kode karyawan Sales. |
| `gudang_code` | Ya | Kode **gudang asal** (Gudang Pusat). |
| `tanggal` | Ya | Format `YYYY-MM-DD`. |
| `details` | Ya | Array produk yang diambil. |
| `details.*.sku_product` | Ya | Kode SKU produk. |
| `details.*.qty` | Ya | Jumlah yang diambil **dalam satuan KAS** (sistem akan konversi ke KG otomatis). |

```json
{
    "emp_code": "EMP-001",
    "gudang_code": "GDG-001",
    "tanggal": "2026-09-12",
    "details": [
        { "sku_product": "TLR-001", "qty": 10 }
    ]
}
```

> `qty` di sini adalah dalam satuan **KAS**. Sistem otomatis mengkalikan dengan `sku_uom_conversion` (default 15 KG/KAS) untuk mendapatkan nilai KG yang dimutasikan.

---

## 9. Retur Barang (Tukar Guling)

> **Catatan:** Retur bisa dilakukan langsung saat input penjualan (via field `details_retur` di endpoint `POST /api/penjualan`) **atau** secara terpisah menggunakan endpoint di bawah.

### A. Form Retur
**`GET /api/sales/retur/form`**

### B. Input Retur Terpisah
**`POST /api/sales/retur-tukar`**  
**Content-Type: `application/json`**

```json
{
    "jual_code": "INV/202609/0001",
    "tanggal": "2026-09-12",
    "keterangan": "Telur rusak saat pengiriman",
    "details": [
        {
            "sku_product": "TLR-RSK-001",
            "qty": 2.5,
            "harga_kompensasi": 10000
        }
    ]
}
```

---

## 10. Notifikasi

### `GET /api/notifications`

Ambil daftar notifikasi milik Sales yang sedang login (piutang jatuh tempo, telur siap, dll).

**Query Params:** `page` (opsional, untuk pagination)

### `GET /api/notifications/unread-count`

Ambil jumlah notifikasi yang belum dibaca → untuk badge/angka di icon lonceng.

```json
{ "status": "success", "unread_count": 3 }
```

### `POST /api/notifications/{id}/read`

Tandai 1 notifikasi sudah dibaca.

### `POST /api/notifications/read-all`

Tandai semua notifikasi sudah dibaca.

### `POST /api/fcm-token`

Kirim Device Token HP ke Backend agar bisa menerima Push Notification.

```json
{ "fcm_token": "APA91bH...token_panjang..." }
```

> ⚠️ **WAJIB** dipanggil setelah user berhasil login.

---

## 11. Alur Lengkap Status Bayar Penjualan

```
BUAT PENJUALAN (POST /api/penjualan)
     │
     ├── opsi_bayar = "Lunas"       → status_bayar = "Paid"     (selesai)
     │
     ├── opsi_bayar = "Sebagian"    → status_bayar = "Parsial"  
     │                                 (customer bayar nominal_dibayar, sisanya jadi piutang)
     │
     └── opsi_bayar = "Belum Bayar" → status_bayar = "Unpaid"
                                       (100% piutang, tampil di list_unpaid Dashboard)

SAAT CUSTOMER BAYAR CICILAN:
  POST /api/penjualan/bayar-piutang
  → jika sisa_piutang = 0 → status_bayar berubah jadi "Paid" otomatis

SAAT SALES SETOR UANG KE KAS BESAR:
  POST /api/sales/setor
  → Admin menerima notifikasi "Setoran Sales" di Web Admin
```
