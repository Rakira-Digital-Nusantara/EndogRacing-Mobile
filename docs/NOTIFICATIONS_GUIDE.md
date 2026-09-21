# Panduan Integrasi Sistem Notifikasi & Firebase (FCM)
**Endog Racing API**

Dokumen ini berisi panduan teknis, langkah konfigurasi, serta *prompt* yang dapat langsung Anda kirimkan kepada tim Frontend (Web) maupun Mobile Developer (Kandang & Sales) untuk mengimplementasikan fitur notifikasi dan Firebase Cloud Messaging (FCM).

---

## 1. Prompt untuk Tim Frontend **Web Admin**

Bapak bisa langsung *copy-paste* teks di bawah ini dan dikirimkan ke **Tim Web Developer**:

> **[PROMPT UNTUK TIM WEB DEVELOPER]**
>
> "Halo Tim Web,
>
> Sistem Backend sudah mendukung **Sistem Notifikasi Tersentralisasi** untuk Web Admin. Semua notifikasi otomatis (seperti: PO datang, penjualan baru, setoran sales, pakan hampir habis, piutang jatuh tempo, dll) sudah dicatat di database backend dan siap dikonsumsi oleh halaman Web Admin.
>
> **Tugas Kalian di Halaman Web Admin:**
> 1. Tambahkan **Icon Lonceng Notifikasi** di header/navbar halaman Web Admin.
> 2. Panggil `GET /api/notifications/unread-count` untuk menampilkan **badge angka merah** di icon lonceng. Lakukan polling setiap 30 detik agar badge selalu update.
> 3. Jika lonceng diklik, tampilkan dropdown/panel berisi daftar notifikasi dengan memanggil `GET /api/notifications`.
> 4. Setiap notifikasi yang diklik, tandai sebagai terbaca dengan `POST /api/notifications/{id}/read`.
> 5. Sediakan tombol **"Tandai Semua Dibaca"** dengan `POST /api/notifications/read-all`.
>
> **Notifikasi yang Akan Diterima oleh Admin:**
> - 🟡 PO Baru Dibuat (saat Kandang/Admin input Purchase Order)
> - 🟢 PO Datang & Diterima (saat Penerimaan Barang diinput)
> - 🔵 Penjualan Baru dari Sales
> - 🔴 Retur Penjualan (Tukar Guling)
> - 💰 Setoran Sales (saat Sales menyetor uang)
> - 📦 Penarikan Barang Deposit Sales
> - 🐔 Produksi Telur Baru (Laporan Panen dari Kandang)
> - ✅ Checklist Kebersihan Kandang Selesai
> - ⚠️ Pakan Hampir Habis (Stok ≤ 100 KG) — Notif Otomatis Pagi Hari
> - 💸 Piutang Sales Jatuh Tempo — Notif Otomatis Pagi Hari
>
> Detail format response JSON ada di Section 2 dokumen ini. Terima kasih!"

### 1.1 Contoh Implementasi (Polling) di React/Vue.js (Web Admin)
Karena Web Admin bersifat *dashboard*, cara paling sederhana tanpa menggunakan WebSocket adalah dengan melakukan *Long Polling* setiap 30 detik untuk mengecek apakah ada notifikasi baru.

```javascript
// Contoh menggunakan React / Axios
import React, { useState, useEffect } from 'react';
import axios from 'axios';

const NotificationBell = () => {
  const [unreadCount, setUnreadCount] = useState(0);

  // Fungsi untuk menarik jumlah notifikasi
  const fetchUnreadCount = async () => {
    try {
      const response = await axios.get('http://api.endogracing.test/api/notifications/unread-count', {
        headers: { Authorization: `Bearer ${localStorage.getItem('token')}` }
      });
      setUnreadCount(response.data.unread_count);
    } catch (error) {
      console.error("Gagal menarik notifikasi", error);
    }
  };

  useEffect(() => {
    // Tarik notifikasi saat pertama kali render
    fetchUnreadCount();

    // Setup polling setiap 30 detik (30000 ms)
    const intervalId = setInterval(() => {
      fetchUnreadCount();
    }, 30000);

    return () => clearInterval(intervalId); // Bersihkan saat komponen unmount
  }, []);

  return (
    <div className="notification-icon">
      <i className="fa fa-bell"></i>
      {unreadCount > 0 && <span className="badge-merah">{unreadCount}</span>}
    </div>
  );
};

export default NotificationBell;
```

---

## 1B. Prompt untuk Tim **Mobile Kandang**

Bapak bisa langsung *copy-paste* teks di bawah ini dan dikirimkan ke **Tim Developer Aplikasi Kandang**:

> **[PROMPT UNTUK TIM MOBILE KANDANG]**
>
> "Halo Tim Mobile Kandang,
>
> Aplikasi Kandang sekarang mendukung notifikasi in-app. Semua notifikasi yang relevan untuk user Kandang sudah tercatat di backend.
>
> **Tugas Kalian di Aplikasi Mobile Kandang:**
> 1. Tambahkan **Icon Lonceng / Badge Notifikasi** di halaman utama aplikasi Kandang.
> 2. Panggil `GET /api/notifications/unread-count` untuk menampilkan angka di badge. Lakukan refresh setiap kali halaman aktif/di-resume.
> 3. Buat halaman **Riwayat Notifikasi** yang memanggil `GET /api/notifications`.
> 4. **WAJIB:** Setelah user Kandang berhasil Login, segera panggil fungsi FCM untuk mendapatkan Device Token, lalu kirimkan ke `POST /api/fcm-token`. Ini diperlukan agar notifikasi Push bisa masuk ke HP meskipun aplikasi di-close.
>
> **Notifikasi yang Akan Diterima User Kandang:**
> - ⚠️ Pakan Hampir Habis (Stok ≤ 100 KG) — Otomatis setiap pagi pukul 07:00
>
> Untuk langkah setup Firebase SDK di Flutter, lihat **Section 3B** di dokumen ini. Terima kasih!"

---

## 1C. Prompt untuk Tim **Mobile Sales**

Bapak bisa langsung *copy-paste* teks di bawah ini dan dikirimkan ke **Tim Developer Aplikasi Sales**:

> **[PROMPT UNTUK TIM MOBILE SALES]**
>
> "Halo Tim Mobile Sales,
>
> Aplikasi Sales sekarang mendukung notifikasi in-app dari Backend. Khusus untuk Sales, ada notifikasi penting yang perlu kalian tampilkan di aplikasi.
>
> **Tugas Kalian di Aplikasi Mobile Sales:**
> 1. Tambahkan **Icon Lonceng / Badge Notifikasi** di halaman utama aplikasi Sales.
> 2. Panggil `GET /api/notifications/unread-count` untuk menampilkan angka di badge.
> 3. Buat halaman **Riwayat Notifikasi** yang memanggil `GET /api/notifications`.
> 4. **WAJIB:** Setelah user Sales berhasil Login, segera dapatkan FCM Device Token lalu kirimkan ke `POST /api/fcm-token`. Ini agar notifikasi Push bisa masuk ke HP Sales meskipun aplikasi di-close.
>
> **Notifikasi yang Akan Diterima User Sales:**
> - 🐣 Produksi Telur Siap (Laporan Panen Telur masuk dari Kandang — artinya stok telur di Gudang sudah bertambah dan siap dijual)
> - 💸 Piutang Jatuh Tempo (Peringatan bahwa ada invoice pelanggan Sales yang sudah jatuh tempo) — Otomatis setiap pagi pukul 07:00
>
> Untuk langkah setup Firebase SDK di Flutter, lihat **Section 3B** di dokumen ini. Terima kasih!"

---


## 2. Dokumentasi Endpoint API Notifikasi

Semua endpoint di bawah ini membutuhkan **Bearer Token** dari Sanctum (user harus sudah login).

### 2.1 Ambil Daftar Notifikasi
- **Endpoint**: `GET /api/notifications`
- **Tujuan**: Menampilkan seluruh riwayat notifikasi milik user yang sedang login, diurutkan dari yang paling baru. Sudah otomatis berupa pagination.
- **Query Params (Opsional)**:
  - `page` (integer): Halaman ke berapa (Default: 1)
- **Response**:
```json
{
  "status": "success",
  "data": [
    {
      "id": "9b12x-...",
      "type": "App\\Notifications\\PakanHampirHabisNotification",
      "data": {
        "title": "Peringatan: Pakan Hampir Habis",
        "message": "Stok pakan Japfa di Gudang Pusat tersisa 90 KG. Segera lakukan pemesanan (PO)."
      },
      "read_at": null,
      "created_at": "2026-09-12T01:00:00.000000Z"
    }
  ],
  "links": {...},
  "meta": {...}
}
```

### 2.2 Ambil Jumlah Notifikasi Belum Dibaca (Unread Count)
- **Endpoint**: `GET /api/notifications/unread-count`
- **Tujuan**: Untuk menampilkan angka "Badge Merah" di icon lonceng aplikasi.
- **Response**:
```json
{
  "status": "success",
  "unread_count": 5
}
```

### 2.3 Tandai Satu Notifikasi Sudah Dibaca
- **Endpoint**: `POST /api/notifications/{id}/read`
- **Tujuan**: Menandai notifikasi spesifik (berdasarkan `id` dari response list notifikasi) bahwa sudah dibaca oleh user.
- **Response**:
```json
{
  "status": "success",
  "message": "Notification marked as read"
}
```

### 2.4 Tandai Semua Notifikasi Sudah Dibaca
- **Endpoint**: `POST /api/notifications/read-all`
- **Tujuan**: Tombol "Mark all as read". Mengubah semua status notif menjadi terbaca sekaligus.
- **Response**:
```json
{
  "status": "success",
  "message": "All notifications marked as read"
}
```

### 2.5 Kirim FCM Token ke Backend (Khusus Mobile)
- **Endpoint**: `POST /api/fcm-token`
- **Tujuan**: Mengirim Device Token dari HP ke Backend agar Backend bisa mengirim Push Notification. Harus dieksekusi oleh aplikasi mobile sesaat setelah user berhasil Login ke dalam aplikasi.
- **Body Request (JSON)**:
```json
{
  "fcm_token": "APA91bH...token_panjang_dari_google..."
}
```
- **Response**:
```json
{
  "status": "success",
  "message": "FCM Token berhasil disimpan"
}
```

---

## 3. Langkah-Langkah Konfigurasi Firebase FCM (Server & Mobile)

> **Konsep Penting — Pahami Ini Dulu!**
>
> Firebase itu ibarat sebuah **kantor pos perantara** milik Google. Agar Server bisa "kirim surat" (Push Notification) ke HP User, dan HP User bisa "menerima surat" tersebut, keduanya harus **terdaftar di kantor pos yang SAMA** — yaitu **1 Firebase Project yang sama**.
>
> Jadi alurnya adalah:
> ```
> [Server Laravel] ---kirim pesan---> [Firebase Project "Endog Racing"] ---push ke HP---> [Aplikasi Mobile]
> ```
>
> **File JSON yang dimaksud ADA 2 JENIS yang BERBEDA**, keduanya berasal dari Firebase Project yang sama:
>
> | File | Untuk Siapa | Isinya |
> |------|-------------|--------|
> | `firebase-auth.json` (Service Account) | **Server Laravel** | Kunci rahasia agar Server bisa mengirim notifikasi via Firebase |
> | `google-services.json` | **Aplikasi Mobile Android** | Kunci agar Aplikasi HP bisa terhubung ke Firebase yang sama |
>
> ⚠️ **Bapak sudah download `firebase-auth.json` untuk Server. File `google-services.json` ini file yang berbeda, dan Tim Mobile yang perlu mendownload-nya dari Firebase Project yang sama.**

---

### 3A. Konfigurasi di sisi Backend (Server Laravel)

> **Status: Sudah Bapak Lakukan (Download `firebase-auth.json`)**

Berikut adalah pengingat langkah yang sudah atau perlu Bapak selesaikan di sisi Server:

1. ✅ **Buat Project di Firebase Console** — Buka [Firebase Console](https://console.firebase.google.com/) dan buat project (misal: "Endog Racing App"). *(Sudah dilakukan)*
2. ✅ **Download `firebase-auth.json` (Service Account)** — Di Firebase Console > Gear (Project Settings) > Tab `Service accounts` > klik `Generate new private key`. *(Sudah Bapak download)*
3. **Pasang file di Server Laravel**:
   - Upload/taruh file `firebase-auth.json` ke dalam folder `storage/app/` di server.
   - Pastikan nama filenya sesuai (misal: `storage/app/firebase-auth.json`).
4. **Instal Package kreait di Laravel** (Sangat Penting):
   - Buka **Terminal Laragon** (jangan gunakan CMD biasa jika composer belum masuk ke *environment variable* Windows).
   - Pastikan path terminal berada di `c:\laragon\www\EndogRacing-API`.
   - Jalankan perintah berikut:
   ```bash
   composer require kreait/laravel-firebase
   ```
5. **Tambahkan konfigurasi ke file `.env`**:
   ```env
   FIREBASE_CREDENTIALS=storage/app/firebase-auth.json
   ```

---

### 3B. Konfigurasi di Sisi Mobile — **Aplikasi Kandang & Sales** (Flutter/Android)

> **Penting: Tim Mobile TIDAK membuat Firebase Project baru!**
>
> Tim Mobile menggunakan **Firebase Project yang SAMA** yang sudah Bapak buat di langkah 3A. Mereka hanya perlu men-daftarkan aplikasi HP mereka ke dalam project tersebut, lalu mendownload file konfigurasi yang berbeda yaitu `google-services.json`.

**Langkah untuk Tim Mobile Developer:**

1. **Daftarkan Aplikasi HP ke Firebase Project yang sudah ada**:
   - Buka [Firebase Console](https://console.firebase.google.com/) > Pilih project **"Endog Racing App"** (yang sudah dibuat Bapak).
   - Klik `Add App` > Pilih icon **Android** (karena kebanyakan Flutter/Android).
   - Masukkan **Package Name** aplikasinya:
     - Untuk App Kandang: misalnya `com.endogracing.kandang`
     - Untuk App Sales: misalnya `com.endogracing.sales`
   - Klik `Register App`.
   - Firebase akan menampilkan tombol **Download `google-services.json`** — download file ini.

2. **Pasang `google-services.json` ke Proyek Flutter/Android**:
   - Letakkan file `google-services.json` di dalam folder `android/app/` di dalam project code Flutter/Android mereka.
   - Ini adalah file yang BERBEDA dari `firebase-auth.json` milik Server. Keduanya berasal dari Firebase Project yang sama, tapi fungsinya berbeda.

3. **Tambahkan Plugin FCM ke `android/build.gradle`** (Tim Mobile sudah paham ini):
   - Tambahkan `google-services` plugin di file `android/build.gradle` dan `android/app/build.gradle`.

4. **Integrasi FCM SDK di Code Flutter**:
   ```dart
   // Tambahkan di pubspec.yaml:
   // firebase_core: ^latest
   // firebase_messaging: ^latest

   // Di main.dart atau auth service, setelah login berhasil:
   await Firebase.initializeApp();
   FirebaseMessaging messaging = FirebaseMessaging.instance;

   // Minta izin notifikasi ke user (Android 13+)
   NotificationSettings settings = await messaging.requestPermission();

   // Dapatkan Device Token
   String? fcmToken = await messaging.getToken();

   // KIRIM TOKEN KE API BACKEND (WAJIB!)
   if (fcmToken != null) {
     await http.post(
       Uri.parse('https://api.endogracing.com/api/fcm-token'),
       headers: {
         'Authorization': 'Bearer $loginToken',
         'Content-Type': 'application/json',
       },
       body: jsonEncode({'fcm_token': fcmToken}),
     );
   }
   ```

5. **Tangani Notifikasi di Background & Foreground**:
   ```dart
   // Saat aplikasi di foreground
   FirebaseMessaging.onMessage.listen((RemoteMessage message) {
     print('Notifikasi masuk: ${message.notification?.title}');
     // Tampilkan local notification atau update badge
   });

   // Saat user tap notifikasi dari background
   FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
     // Navigasi ke halaman yang sesuai
   });
   ```

---

> **Ringkasan Alur Lengkap:**
>
> ```
> 1. Bapak buat Firebase Project "Endog Racing" (sudah ✅)
> 2. Bapak download firebase-auth.json → pasang di Server Laravel (sudah ✅)
> 3. Tim Mobile daftarkan App Kandang ke Firebase Project yang SAMA
> 4. Tim Mobile download google-services.json → pasang di folder android/app/
> 5. Setelah user login → App Mobile ambil FCM Token → kirim ke /api/fcm-token
> 6. Saat ada event (penjualan, PO, dll) → Server kirim notif via Firebase → HP User menerima Push Notification
> ```

*(Tim Mobile Developer sangat familiar dengan tahapan 3B ini, cukup arahkan mereka ke dokumen ini dan berikan akses ke Firebase Console Project "Endog Racing" agar mereka bisa mendaftarkan aplikasinya.)*
