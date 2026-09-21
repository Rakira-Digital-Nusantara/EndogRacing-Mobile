# Permintaan Pembuatan API Fitur Customer (Untuk Tim Backend)

Halo Tim Backend,
Untuk mendukung fitur Menu Customer di aplikasi Mobile (Flutter), kami membutuhkan penambahan 3 buah *endpoint* API baru/modifikasi. Berikut adalah spesifikasi *payload* dan *response* yang dibutuhkan oleh aplikasi Mobile (sesuai dengan desain UI).

---

## 1. API Lihat Daftar & Detail Customer
**Endpoint:** `GET /api/customers`
**Tujuan:** Menampilkan daftar pelanggan lengkap dengan alamat, nomor telepon, dan **Total Sisa Piutang** yang dimiliki pelanggan tersebut (untuk ditampilkan di kartu).

**Response (Contoh):**
```json
{
    "status": "success",
    "data": [
        {
            "customer_code": "CUS001",
            "customer_name": "Toko Abadi Nan Jaya",
            "address": "Jl. Merdeka No. 123, Kec. Cibadak, Sukabumi",
            "phone": "0812-3456-7890",
            "sisa_piutang": 500000 
        },
        {
            "customer_code": "CUS002",
            "customer_name": "Toko Berkah",
            "address": "Jl. Sudirman No. 45, Bandung",
            "phone": "0899-1122-3344",
            "sisa_piutang": 0 
        }
    ]
}
```
> **Catatan Backend:** Kolom `sisa_piutang` didapat dari hasil `SUM(sisa_piutang)` pada tabel transaksi penjualan milik customer tersebut. Jika tidak ada hutang, return `0`.

---

## 2. API Edit Data Customer
**Endpoint:** `PUT /api/customers/{customer_code}` (Atau `POST` jika menggunakan method spoofing `_method=PUT`)
**Tujuan:** Menyimpan perubahan data customer ketika Sales mengklik tombol "Edit Data".

**Request Body (JSON):**
```json
{
    "customer_name": "Toko Abadi Nan Jaya Baru",
    "address": "Jl. Merdeka No. 123, Kec. Cibadak (Update)",
    "phone": "0812-0000-0000"
}
```

**Response (Contoh):**
```json
{
    "status": "success",
    "message": "Data customer berhasil diubah",
    "data": {
        "customer_code": "CUS001",
        "customer_name": "Toko Abadi Nan Jaya Baru",
        ...
    }
}
```

---

## 3. API Lihat History Penjualan per Customer
**Endpoint:** `GET /api/penjualan?customer_code={customer_code}`
**Tujuan:** Saat tombol "Riwayat" ditekan, aplikasi akan memanggil daftar riwayat transaksi **khusus untuk toko tersebut**.

> **Catatan Backend:** Endpoint ini sebetulnya sudah ada (`GET /api/penjualan`). Tim backend **hanya perlu menambahkan filter opsional** `customer_code` di controller-nya.

**Logika di Controller (Contoh Laravel):**
```php
public function index(Request $request) {
    $query = Penjualan::query();

    // Filter berdasarkan customer jika parameter dikirim
    if ($request->has('customer_code')) {
        $query->where('customer_code', $request->customer_code);
    }

    // Filter status bayar yang sudah ada
    if ($request->has('status_bayar')) {
        // ... logika lama
    }

    $data = $query->get();
    return response()->json(['status' => 'success', 'data' => $data]);
}
```

---
Terima kasih! Jika API-nya sudah siap, mohon kabari tim Mobile agar bisa langsung diintegrasikan. 🚀
