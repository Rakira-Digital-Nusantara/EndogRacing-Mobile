# Dokumentasi API & Panduan Kolaborasi Tim

Dokumen ini berisi spesifikasi API Autentikasi yang baru saja dibuat, beserta panduan kerja sama agar Anda (Backend), Frontend Web, dan Frontend Mobile dapat bekerja dengan mulus dan terstruktur.

---

## Bagian 1: Spesifikasi API (Autentikasi)

Semua endpoint di bawah ini memiliki _base URL_ `https://api-endogracing.rakiradigital.com` (atau menyesuaikan domain server Anda saat di-*deploy*).

### 1. Login Web
Hanya ditujukan untuk user dengan Role: **Admin** atau **Owner**.
- **URL**: `/api/login/web`
- **Method**: `POST`
- **Headers**: `Accept: application/json`
- **Request Body (JSON)**:
  ```json
  {
    "usr_loginname": "admin_hendra",
    "usr_password": "Password123!"
  }
  ```
- **Success Response (200 OK)**:
  ```json
  {
    "message": "Login Web berhasil",
    "access_token": "1|abcde12345...",
    "token_type": "Bearer",
    "user": {
      "id": 1,
      "usr_fullname": "Hendra",
      "usr_loginname": "admin_hendra",
      "usr_rolecode": "Admin",
      "usr_status": "Aktif",
      "...": "..."
    }
  }
  ```

### 2. Login Mobile
Hanya ditujukan untuk user dengan Role: **Sales** atau **Kandang**.
- **URL**: `/api/login/mobile`
- **Method**: `POST`
- **Headers**: `Accept: application/json`
- **Request Body (JSON)**:
  ```json
  {
    "usr_loginname": "kandang_01",
    "usr_password": "Password123!"
  }
  ```
- **Success Response (200 OK)**:
  ```json
  {
    "message": "Login Mobile berhasil",
    "access_token": "2|fghij67890...",
    "token_type": "Bearer",
    "user": { "...": "..." },
    "next_step": "verify_pin" 
  }
  ```
  *(Catatan untuk Mobile: Jika `next_step` = `verify_pin`, jangan langsung masuk ke dashboard, tapi tampilkan layar input PIN).*

### 3. Validasi PIN (Khusus Mobile - Role Kandang)
- **URL**: `/api/kandang/verify-pin`
- **Method**: `POST`
- **Headers**: 
  - `Accept: application/json`
  - `Authorization: Bearer <access_token_dari_login>`
- **Request Body (JSON)**:
  ```json
  {
    "kdg_code": "KDG-001",
    "kdg_pin": "123456"
  }
  ```
- **Success Response (200 OK)**:
  ```json
  {
    "message": "PIN Kandang valid",
    "kandang": {
       "kdg_code": "KDG-001",
       "kdg_nama": "Kandang Induk",
       "...": "..."
    }
  }
  ```

### 4. Logout (Web & Mobile)
- **URL**: `/api/logout`
- **Method**: `POST`
- **Headers**: 
  - `Accept: application/json`
  - `Authorization: Bearer <access_token>`
- **Success Response (200 OK)**:
  ```json
  {
    "message": "Logout berhasil"
  }
  ```

### 🚨 Format Error Standard (422 Unprocessable Entity)
Tim Frontend wajib menangkap status `422` dan mengambil isi error untuk ditampilkan di layar, karena Laravel selalu menggunakan struktur ini untuk validasi gagal atau _password_ salah:
```json
{
  "message": "Username (login name) wajib diisi. (and 1 more error)",
  "errors": {
    "usr_loginname": [
      "Kredensial yang diberikan tidak cocok dengan data kami."
    ],
    "usr_password": [
      "Password harus mengandung setidaknya 1 huruf besar, 1 angka, dan 1 simbol."
    ]
  }
}
```

---

## Bagian 2: Apa Saja yang Dibutuhkan untuk Kerja Sama Tim?

Agar Anda dan teman-teman _Frontend_ bisa jalan beriringan, lakukan 5 hal wajib berikut:

> [!IMPORTANT]
> **1. Buat API Documentation/Collection**
> Bagikan API Collection. Jangan biarkan Frontend menebak-nebak apa isi respon API Anda. 
> - **Opsi Termudah:** Gunakan **Postman** atau **Insomnia**, lalu _Export_ file collection-nya berikan ke teman Anda.
> - **Opsi Advance:** Nanti kita bisa install package seperti `Scribe` atau `Swagger` di Laravel agar dokumentasi otomatis men-generate halaman web interaktif.

> [!WARNING]
> **2. Konfigurasi CORS (Cross-Origin Resource Sharing)**
> Untuk **Frontend Web** (seperti React/Vue/Angular), browser akan memblokir request ke API Anda jika beda _port_ (misal Backend di `localhost:8000`, Frontend di `localhost:3000`).
> - Buka file `config/cors.php` (atau sesuaikan dengan settingan Laravel 11 Anda). 
> - Pastikan URL Frontend Web teman Anda (contoh `http://localhost:3000`) dimasukkan ke bagian `allowed_origins`.

> [!TIP]
> **3. Kesepakatan Header Global**
> Wajibkan _Frontend_ agar selalu menempelkan header ini pada **setiap** HTTP Request yang mengarah ke Laravel:
> - `Accept: application/json`
> 
> Tanpa header ini, kalau ada _error_ di Laravel, Frontend bisa malah dikembalikan halaman HTML putih (error 500 html page) alih-alih teks JSON!

> [!NOTE]
> **4. Penyimpanan Token (Token Management)**
> Sepakati bagaimana Frontend menyimpan `access_token`:
> - **Frontend Web:** Disarankan disimpan di memori atau *Cookies*, tapi jika mengejar kecepatan bisa simpan di `localStorage`.
> - **Frontend Mobile (Flutter/Kotlin/RN):** Wajib simpan token di penyimpanan terenkripsi seperti `Flutter Secure Storage` atau `EncryptedSharedPreferences`. Jangan di storage biasa/SQLite murni.

> [!TIP]
> **5. Komunikasi Base URL dan Environment**
> Jangan pernah biarkan Frontend melakukan *hardcode* alamat IP/URL (seperti `https://api-endogracing.rakiradigital.com/api/login/web`) langsung di dalam kode mereka. Minta Frontend meletakkan _base URL_ (`https://api-endogracing.rakiradigital.com/api`) di dalam `.env` aplikasi mereka, agar nanti jika rilis ke server produksi lain, mereka cukup mengubah satu file `.env` saja.
