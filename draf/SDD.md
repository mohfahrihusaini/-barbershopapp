# Software Design Document (SDD)
**Project:** Kece Barbershop App  
**Architecture Pattern:** Provider (State Management) + Service Layer Architecture

---

## 1. System Architecture
Aplikasi menggunakan pola arsitektur **MVVM (Model-View-ViewModel)** yang disederhanakan menggunakan **Provider**:

* **View (UI):** Folder `presentation/screens`. Menangani tampilan antarmuka.
* **ViewModel (Provider):** Folder `providers`. Menangani *business logic* dan *state* aplikasi.
* **Model:** Folder `data/models`. Representasi struktur data (JSON Parsing).
* **Service:** Folder `data/services`. Menangani komunikasi langsung ke API (Appwrite).

---

## 2. Database Design (Appwrite Collections)

### 2.1 Collection: Users
Menyimpan data profil pengguna.
| Attribute Key | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `nama` | String | Yes | Nama Lengkap User |
| `email` | String | Yes | Email User |
| `no_hp` | String | Yes | Nomor Handphone |
| `role` | String | Yes | `admin` atau `pelanggan` |

### 2.2 Collection: Layanan
Menyimpan jenis servis yang tersedia.
| Attribute Key | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `nama_layanan`| String | Yes | Contoh: Potong Rambut |
| `harga` | Integer| Yes | Harga dalam Rupiah |
| `durasi_menit`| Integer| Yes | Estimasi waktu pengerjaan |

### 2.3 Collection: Barber
Menyimpan data karyawan/kapster.
| Attribute Key | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `name_barber` | String | Yes | Nama Kapster |
| `spesialisasi`| String | Yes | Keahlian (e.g., Fade Cut) |
| `status` | String | Yes | `Tersedia` / `Tidak Tersedia` |

### 2.4 Collection: Reservasi
Menyimpan data booking.
| Attribute Key | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `id_user` | String | Yes | Relasi ke Auth ID |
| `id_layanan` | String | Yes | Relasi ke Collection Layanan |
| `id_barber` | String | Yes | Relasi ke Collection Barber |
| `tanggal` | String | Yes | Format ISO8601 |
| `waktu_mulai` | String | Yes | Format HH:mm |
| `status_antrian`| String | Yes | `Menunggu`, `Confirmed`, `Dibatalkan` |

### 2.5 Collection: Pembayaran
Menyimpan bukti transfer.
| Attribute Key | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `id_reservasi` | String | Yes | Relasi ke ID Reservasi |
| `jumlah_bayar` | Integer| Yes | Total yang dibayar |
| `bukti_bayar` | String | Yes | URL Gambar dari Storage |
| `metode_pembayaran`| String | Yes | Contoh: Transfer BCA |
| `status_verifikasi`| String | Yes | `Pending`, `Lunas`, `Ditolak` |

---

## 3. Code Structure

```text
lib/
├── config/
│   └── app_constants.dart       # Konfigurasi ID Project & Collections
├── data/
│   ├── models/                  # Class Model (Barber, Layanan, User, dll)
│   └── services/
│       ├── appwrite_client.dart # Inisialisasi SDK Appwrite
│       ├── database_service.dart# CRUD ke Database
│       └── storage_service.dart # Upload File ke Storage
├── providers/
│   ├── auth_provider.dart       # Logic Login/Register
│   └── booking_provider.dart    # Logic Booking, Payment, Admin Features
├── presentation/
│   ├── screens/
│   │   ├── auth/                # LoginScreen, RegisterScreen
│   │   ├── admin/               # DashboardAdmin, ManageService, ManageBarber, Validation
│   │   └── client/              # HomeScreen, BookingForm, Payment, History, Profile
│   └── widgets/                 # Widget Reusable (jika ada)
└── main.dart                    # Entry Point & MultiProvider Setup