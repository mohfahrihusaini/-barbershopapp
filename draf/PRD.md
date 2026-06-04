# Product Requirements Document (PRD)
**Project Name:** Kece Barbershop Mobile App  
**Platform:** Android (Mobile)  
**Tech Stack:** Flutter (Frontend), Appwrite (Backend)  
**Version:** 1.0  
**Status:** Final Draft

---

## 1. Introduction
### 1.1 Background
Antrian di barbershop seringkali tidak teratur dan memakan waktu lama, menyebabkan pelanggan merasa bosan dan berpotensi membatalkan niat cukur. Pemilik barbershop juga kesulitan mengelola jadwal dan mencatat transaksi secara manual.

### 1.2 Objective (Tujuan)
Membangun aplikasi mobile yang memungkinkan pelanggan untuk melakukan reservasi layanan cukur secara online (booking), memilih kapster favorit, dan melakukan pembayaran non-tunai. Bagi admin, aplikasi ini bertujuan mempermudah pengelolaan layanan, data karyawan, dan validasi transaksi.

---

## 2. Target Audience
1.  **Pelanggan (Client):** Pria/Wanita yang ingin mencukur rambut tanpa antre lama di lokasi.
2.  **Admin (Owner/Manager):** Pemilik barbershop yang membutuhkan sistem manajemen operasional yang efisien.

---

## 3. Key Features (Fitur Utama)

### 3.1 Fitur Pelanggan
* **Registrasi & Login:** Masuk menggunakan email.
* **Dashboard:** Melihat informasi promo/sapaan dan daftar layanan.
* **Booking System:** Memilih Layanan, Barber (Kapster), Tanggal, dan Jam.
* **Pembayaran:** Upload bukti transfer pembayaran.
* **Riwayat Pesanan:** Melihat status booking (Menunggu/Confirmed).
* **Profil:** Melihat data diri dan Logout.

### 3.2 Fitur Admin
* **Dashboard Admin:** Akses menu pengelolaan.
* **Kelola Layanan (CRUD):** Tambah, Edit, Hapus jenis layanan & harga.
* **Kelola Barber (CRUD):** Tambah, Edit, Hapus data kapster & status ketersediaan.
* **Validasi Pembayaran:** Menerima atau Menolak bukti transfer pelanggan.
* **Sinkronisasi Status:** Otomatis update status reservasi saat pembayaran divalidasi.

---

## 4. User Flow (Alur Pengguna)
1.  User Login -> Masuk Dashboard.
2.  User Klik "Buat Reservasi" -> Pilih Layanan -> Pilih Barber -> Pilih Waktu.
3.  User Submit -> Sistem membuat Reservasi (Status: Menunggu).
4.  User diarahkan ke Halaman Pembayaran -> Upload Bukti Transfer -> Submit.
5.  Admin menerima notifikasi data pembayaran -> Admin memverifikasi (Terima/Tolak).
6.  Status Reservasi User berubah menjadi "Confirmed" (jika diterima).
7.  User datang ke lokasi sesuai jadwal.

---

## 5. Success Metrics
* Pengurangan waktu tunggu pelanggan di lokasi fisik.
* Peningkatan efisiensi pencatatan transaksi (digital vs manual).
* Sistem berjalan tanpa error (Crash-free users > 99%).