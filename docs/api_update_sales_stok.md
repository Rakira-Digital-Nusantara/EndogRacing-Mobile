# Update Dokumentasi API: Sales Dashboard

Berikut adalah panduan dan instruksi perubahan struktur API untuk disampaikan kepada **Tim Mobile (Frontend Developer)** terkait update logika Stok pada halaman Dashboard Sales.

> [!IMPORTANT]
> **Endpoint:** `GET /api/sales/dashboard`
> Sistem tidak lagi mengirimkan stok spesifik untuk 1 jenis telur (hardcode). Stok Gudang dan Stok Mobil sekarang dikelompokkan dan ditampilkan secara **dinamis** dalam bentuk array (list) untuk **semua SKU yang berkategori Telur**.

## 1. Perubahan Struktur Response (JSON)

API sekarang melampirkan dua array baru di dalam objek `data`, yaitu `rincian_stok_mobil` dan `rincian_stok_pusat`. Setiap objek di dalam array ini memiliki `harga_sentral`-nya masing-masing.

### Contoh Response Terbaru:
```json
{
    "status": "success",
    "data": {
        "harga_sentral": 27000, 
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

1. **Gunakan Looping (ListBuilder/RecyclerView):** 
   Untuk menampilkan Stok Gudang maupun Stok Sales, harap jangan lagi mengambil nilai dari variabel tunggal untuk telur utuh. Buatlah list dinamis dengan melakukan looping terhadap array `data.rincian_stok_mobil` dan `data.rincian_stok_pusat`.
   
2. **Ambil Harga Sentral dari Detail:**
   Tampilkan `harga_sentral` langsung dari dalam array rincian stok (`item.harga_sentral`) agar harga telur utuh dan telur rusak tidak tertukar/sama.
   
3. **Konversi KG ke KAS sudah disediakan Backend:**
   Mobile tidak perlu menghitung pembagian 15 kg lagi. Cukup mapping field `qty_kas` untuk menampilkan jumlah Kas/Tumpuk, dan `qty_kg` untuk menampilkan jumlah KG.
   
4. **Variabel `stok_mobil` dan `stok_pusat` di luar array:**
   Ini adalah total akumulasi keseluruhan (KG) dari semua varian telur. Anda bisa menggunakannya jika ada section di UI yang hanya meminta "Total Telur Keseluruhan" tanpa peduli itu rusak atau utuh.

> [!NOTE]
> Semua varian produk dengan kategori "Telur" di master data akan otomatis masuk ke array ini. Jadi, tampilan mobile akan otomatis menyesuaikan diri jika besok ada penambahan varian baru (misal: "Telur Puyuh").
