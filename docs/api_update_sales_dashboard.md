# Update Dokumentasi API: Sales Dashboard

Berikut adalah panduan dan instruksi perubahan struktur API untuk disampaikan kepada **Tim Mobile (Frontend Developer)** terkait update logika Stok dan Harga pada halaman Dashboard Sales.

> [!IMPORTANT]
> **Endpoint:** `GET /api/sales/dashboard`
> Sistem tidak lagi mengirimkan stok spesifik untuk 1 jenis telur (hardcode). Stok Gudang, Stok Mobil, dan Harga Hari Ini sekarang dikelompokkan dan ditampilkan secara **dinamis** dalam bentuk array (list) untuk **semua SKU yang berkategori Telur**.

## 1. Perubahan Struktur Response (JSON)

API sekarang melampirkan array baru di dalam objek `data`, yaitu `list_harga_hari_ini`, `rincian_stok_mobil`, dan `rincian_stok_pusat`.

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
        "stok_mobil": 135, 
        "stok_pusat": 1500,
        "rincian_stok_mobil": [
            {
                "sku_product": "TLR-001",
                "sku_name": "Telur Utuh",
                "harga_sentral": 27000,
                "qty_kg": 135,
                "qty_kas": 9
            },
            {
                "sku_product": "TLR-002",
                "sku_name": "Telur Rusak",
                "harga_sentral": 22000,
                "qty_kg": 0,
                "qty_kas": 0
            }
        ],
        "rincian_stok_pusat": [
            {
                "sku_product": "TLR-001",
                "sku_name": "Telur Utuh",
                "harga_sentral": 27000,
                "qty_kg": 1400,
                "qty_kas": 93
            },
            {
                "sku_product": "TLR-002",
                "sku_name": "Telur Rusak",
                "harga_sentral": 22000,
                "qty_kg": 100,
                "qty_kas": 6
            }
        ],
        "total_kg_terjual": 500,
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

2. **Gunakan Looping (ListBuilder/RecyclerView) untuk Stok:** 
   Untuk menampilkan Stok Gudang maupun Stok Sales, harap jangan lagi mengambil nilai dari variabel tunggal untuk telur utuh. Buatlah list dinamis dengan melakukan looping terhadap array `data.rincian_stok_mobil` dan `data.rincian_stok_pusat`.
   
3. **Ambil Harga Sentral dari Detail Stok:**
   Selain ada di `list_harga_hari_ini`, Anda juga bisa menampilkan harga_sentral langsung dari dalam array rincian stok (`item.harga_sentral`).
   
4. **Konversi KG ke KAS sudah disediakan Backend:**
   Mobile tidak perlu menghitung pembagian 15 kg lagi. Cukup mapping field `qty_kas` untuk menampilkan jumlah Kas/Tumpuk, dan `qty_kg` untuk menampilkan jumlah KG.
   
5. **Variabel `stok_mobil` dan `stok_pusat` di luar array:**
   Ini adalah total akumulasi keseluruhan (KG) dari semua varian telur. Anda bisa menggunakannya jika ada section di UI yang hanya meminta "Total Telur Keseluruhan".

6. **Logika Chart Penjualan (Lunas vs Belum):**
   Backend sudah mengupdate logic ini khusus untuk transaksi **Sales yang sedang Login saja**.
   - `total_cash_paid`: Menampilkan total uang tunai (dan lunas) yang sudah ditarik hari ini (Nilai Lunas).
   - `total_piutang`: Menampilkan sisa piutang/tagihan yang masih gantung dari penjualan hari ini (Nilai Belum).

> [!NOTE]
> Semua varian produk dengan kategori "Telur" di master data akan otomatis masuk ke array-array di atas. Tampilan mobile akan otomatis menyesuaikan diri jika besok ada penambahan varian baru.
