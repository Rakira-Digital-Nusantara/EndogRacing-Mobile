# Panduan API: Manajemen Retur & Telur Pecah (Mobile App)

Dokumen ini berisi kontrak JSON lengkap untuk meng- *handle* 3 skenario telur rusak/pecah di lapangan, plus 1 fitur untuk menampilkan dan menyelesaikan hutang barang (ganti telur) keesokan harinya.

---

## 1. Flow "Lapor Pecah di Mobil" (Ubah Wujud)
**Kapan dipakai?** Saat sales keliling di jalan dan mendapati ada telur yang pecah (bukan saat transaksi di toko).
**Fungsi API:** Memotong stok Telur Bagus di mobil dan menambah Telur Rusak di mobil (Ubah wujud).
**Action di Mobile:** Harus dibuatkan tombol khusus (misal: "Lapor Pecah di Mobil").

- **Endpoint:** `POST /api/sales/ubah-wujud`
- **Request Body (JSON):**
```json
{
    "tanggal": "2026-09-16",
    "qty_rusak": 1.5,
    "sku_asal": "1500123",  // Opsional (Jika tidak dikirim, default memotong SKU: 1500123 / Telur Utuh)
    "sku_tujuan": "100001"  // Opsional (Jika tidak dikirim, default menambah SKU: 100001 / Telur Rusak)
}
```
- **Response Success (201):**
```json
{
    "status": "success",
    "message": "Berhasil melaporkan telur pecah. Stok Telur Utuh dikurangi dan Telur Rusak ditambah di mobil."
}
```

---

## 2. Flow "Tukar Guling dari Customer" (Retur Tukar / Hutang Barang)
**Kapan dipakai?** Saat jualan di toko customer, ada telur pecah. Sales janji ganti besok.
**Fungsi API:** Menambah stok Telur Rusak di mobil dan mencatat status *Hutang Barang*. (API ini tidak memotong telur bagus karena pemotongannya dibebankan ke API Penjualan).
**Action di Mobile:** Diinput pada form "Retur Tukar" saat di toko pelanggan.

- **Endpoint:** `POST /api/sales/retur-tukar`
- **Request Body (JSON):**
```json
{
    "tanggal": "2026-09-16",
    "customer_code": "CUST-001", // Optional/Nullable
    "details": [
        {
            "sku_product": "100001", // WAJIB kirim SKU Telur Rusak!
            "qty_retur": 1.0,
            "alasan_retur": "Pecah dari toko"
        }
    ]
}
```
- **Response Success (201):**
```json
{
    "status": "success",
    "message": "Retur tukar berhasil dicatat (Hutang Barang)",
    "data": { ... } // Berisi detail retur header
}
```

---

## 3. Flow "Setor Telur Rusak ke Gudang Pusat"
**Kapan dipakai?** Sore hari saat sales balik ke gudang dan menyerahkan telur rusaknya.
**Fungsi API:** Memindahkan stok Telur Rusak dari mobil ke Gudang Pusat (Stok mobil jadi 0).
**Action di Mobile:** Menggunakan layar form "Refund/Retur" yang sudah ada (Gudang Tujuan: Gudang Central).

- **Endpoint:** `POST /api/sales/retur`
- **Request Body (JSON):**
```json
{
    "gudang_tujuan": "GDG-001", // Kode Gudang Central / Gudang Pusat
    "tanggal": "2026-09-16",
    "details": [
        {
            "sku_product": "100001", // WAJIB pilih Telur Rusak dari dropdown Produk
            "qty": 2.5,
            "alasan_retur": "Setor sisa rusak"
        }
    ]
}
```
- **Response Success (201):**
```json
{
    "status": "success",
    "message": "Retur produk berhasil diproses",
    "data": { ... } // Berisi detail retur header
}
```

---

## 4. Flow Penyelesaian "Hutang Barang" (Besok Harinya)

**Kapan dipakai?** Saat besok harinya sales kembali ke toko customer untuk menyerahkan telur pengganti. 
**Action di Mobile:** 
1. Tampilkan daftar hutang barang yang belum diganti (API Pending).
2. Sediakan tombol "Selesaikan Penggantian" di tiap baris data (API Selesai).

### A. Menampilkan Daftar Hutang Barang (Pending)
- **Endpoint:** `GET /api/penggantian-barang/pending`
- **Response Success (200):**
```json
{
    "status": "success",
    "data": [
        {
            "id": 1,
            "retur_code": "RTR/202609/0001",
            "customer_code": "CUST-001",
            "tanggal": "2026-09-15",
            "status_penggantian": "Belum Diganti",
            "customer": {
                "customer_code": "CUST-001",
                "customer_name": "Toko Barokah"
            },
            "details": [
                {
                    "sku_product": "100001",
                    "qty_retur": 1.0,
                    "keterangan": "Pecah dari toko"
                }
            ]
        }
    ]
}
```

### B. Menyelesaikan Hutang Barang (Kirim Pengganti)
- **Endpoint:** `POST /api/penggantian-barang/{retur_code}/selesai`
  *(Ganti `{retur_code}` di URL dengan `retur_code` dari data pending di atas, contoh: `/api/penggantian-barang/RTR%2F202609%2F0001/selesai`)*
- **Request Body (JSON):**
```json
{
    "sku_pengganti": "1500123" // Opsional (Default: "1500123" Telur Utuh)
}
```
- **Response Success (200):**
```json
{
    "status": "success",
    "message": "Penggantian barang berhasil diselesaikan. Stok telur bagus telah dipotong."
}
```
*(Catatan: Setelah API B dipanggil dengan sukses, baris data tersebut akan otomatis hilang dari daftar API A karena statusnya berubah menjadi 'Sudah Diganti').*
