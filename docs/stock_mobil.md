# Update Dokumentasi API: Sales Dashboard

Berikut adalah panduan dan instruksi perubahan struktur API untuk disampaikan kepada **Tim Mobile (Frontend Developer)** terkait update logika Stok, Harga, dan Diagram Penjualan pada halaman Dashboard Sales.

> [!IMPORTANT]
> **Endpoint:** `GET /api/sales/dashboard`
> Sistem tidak lagi mengirimkan stok spesifik untuk 1 jenis telur (hardcode). Stok Gudang, Stok Mobil, Harga Hari Ini, dan Total Penjualan sekarang dihitung secara **dinamis** untuk **semua SKU yang berkategori Telur**, lengkap dengan hitungan konversi KAS-nya.

## 1. Perubahan Struktur Response (JSON)

API sekarang melampirkan array baru untuk rincian, dan field-field baru dengan akhiran `_kas` (misal: `stok_mobil_kas`, `total_kas_terjual`) di root `data`.

### Contoh Response Terbaru:
```json
{
    "status": "success",
    "data": {
        "harga_sentral": 27000, 
        "list_harga_hari_ini": [
            {
                "sku_name": "Telur Utuh",
                "harga": 27000
            },
            {
                "sku_name": "Telur Rusak/Pecah",
                "harga": 22000
            }
        ],
        "stok_mobil": 30,
        "stok_mobil_kas": 2,
        "stok_pusat": 1500,
        "stok_pusat_kas": 100,
        "total_kg_terjual": 15,
        "total_kas_terjual": 1,
        "rincian_stok_mobil": [
            {
                "sku_product": "TLR-001",
                "sku_name": "Telur Utuh",
                "harga_sentral": 27000,
                "qty_kg": 30,
                "qty_kas": 2
            }
        ],
        "rincian_stok_pusat": [
            {
                "sku_product": "TLR-001",
                "sku_name": "Telur Utuh",
                "harga_sentral": 27000,
                "qty_kg": 1500,
                "qty_kas": 100
            }
        ],
        "total_cash_paid": 1200000,
        "total_piutang": 450000,
        "list_unpaid": [],
        "absensi": {
            "sudah_masuk": true,
            "sudah_pulang": false
        }
    }
}
```

## 2. Instruksi (Perintah) untuk Tim Mobile

Harap berikan instruksi berikut ke programmer Android/Flutter:

1. **Section "Harga Hari Ini" di UI:**
   Jangan lagi mengambil `data.harga_sentral` tunggal untuk ditampilkan di kotak biru (Harga Hari Ini). Silakan buat list/slider untuk menampilkan array `data.list_harga_hari_ini`. Di dalam array tersebut, ambil field `sku_name` (nama telurnya) dan `harga` (harga per KG hari ini).

2. **Diagram "STOK MOBIL" (Terjual vs Sisa):**
   - **Terjual:** Gunakan field `data.total_kg_terjual` untuk KG, dan field `data.total_kas_terjual` untuk KAS.
   - **Sisa (Stok Mobil Saat Ini):** Gunakan field `data.stok_mobil` untuk KG, dan field `data.stok_mobil_kas` untuk KAS.
   - Tidak perlu menghitung konversi pembagian KAS di mobile secara manual lagi, semua angkanya sudah mutlak disediakan oleh API berdasarkan master data produk masing-masing.

3. **Gunakan Looping untuk Rincian Stok (Jika Ada Menu Detail):** 
   Jika Anda membuat UI untuk melihat rincian stok berdasarkan varian (Telur Utuh, Rusak, dll), buatlah list dinamis dengan me-looping `data.rincian_stok_mobil` dan `data.rincian_stok_pusat`. Setiap item di dalamnya sudah memiliki `qty_kg`, `qty_kas`, dan `harga_sentral`.

4. **Logika Chart Penjualan (Lunas vs Belum):**
   Backend sudah mengupdate logic ini khusus untuk transaksi **Sales yang sedang Login saja**.
   - `total_cash_paid`: Menampilkan total uang tunai (dan uang cicilan yang sudah dibayarkan/Lunas) hari ini (Nilai Lunas).
   - `total_piutang`: Menampilkan sisa piutang/tagihan yang belum terbayar/menggantung dari transaksi hari ini (Nilai Belum).
