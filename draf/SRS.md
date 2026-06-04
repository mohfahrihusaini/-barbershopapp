# Software Requirements Specification (SRS)
**Project:** Kece Barbershop App  

---

## 1. Functional Requirements

### 1.1 Authentication Module
* **REQ-AUTH-01:** Sistem harus memungkinkan pengguna mendaftar dengan Email, Password, Nama, dan No HP.
* **REQ-AUTH-02:** Sistem harus membedakan hak akses antara role `admin` dan `pelanggan`.
* **REQ-AUTH-03:** Sistem harus menyimpan sesi login (Auto-login) jika pengguna belum logout.

### 1.2 Booking Module (Client)
* **REQ-BOOK-01:** Pengguna dapat melihat daftar layanan beserta harga dan durasi.
* **REQ-BOOK-02:** Pengguna dapat melihat daftar barber yang tersedia.
* **REQ-BOOK-03:** Pengguna dapat memilih tanggal dan jam operasional (10:00 - 21:00).
* **REQ-BOOK-04:** Sistem menolak input jika data booking tidak lengkap.

### 1.3 Payment Module (Client)
* **REQ-PAY-01:** Pengguna dapat memilih gambar dari galeri perangkat.
* **REQ-PAY-02:** Sistem harus mengunggah gambar ke Cloud Storage.
* **REQ-PAY-03:** Sistem menghubungkan bukti bayar dengan ID Reservasi yang baru dibuat.

### 1.4 Management Module (Admin)
* **REQ-ADM-01:** Admin dapat menambah, mengubah, dan menghapus data Layanan (`nama`, `harga`, `durasi`).
* **REQ-ADM-02:** Admin dapat menambah, mengubah, dan menghapus data Barber (`nama`, `spesialisasi`, `status`).
* **REQ-ADM-03:** Admin dapat melihat daftar pembayaran dengan status `Pending`.
* **REQ-ADM-04:** Admin dapat mengubah status pembayaran menjadi `Lunas` atau `Ditolak`.
* **REQ-ADM-05:** Perubahan status pembayaran harus otomatis mengubah status reservasi terkait.

---

## 2. Non-Functional Requirements
* **NFR-01 (Performance):** Waktu muat data (Load Time) tidak boleh lebih dari 3 detik pada koneksi 4G stabil.
* **NFR-02 (Security):** Password pengguna harus dienkripsi (ditangani oleh Appwrite Auth).
* **NFR-03 (Availability):** Aplikasi membutuhkan koneksi internet untuk beroperasi.
* **NFR-04 (Compatibility):** Aplikasi berjalan pada Android versi 8.0 ke atas.

---

## 3. External Interfaces
* **Database:** Appwrite Database (NoSQL Document Store).
* **Storage:** Appwrite Storage (Image Bucket).
* **Hardware:** Kamera/Galeri Smartphone (untuk upload bukti).