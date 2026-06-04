import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../data/models/barber_model.dart';
import '../data/models/layanan_model.dart';
import '../data/models/reservasi_model.dart';
import '../data/models/pembayaran_model.dart';
import '../data/models/user_model.dart'; // Import UserModel
import '../data/services/database_service.dart';
import '../data/services/storage_service.dart';

class BookingProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final StorageService _storageService = StorageService();

  // State Data
  List<LayananModel> _layananList = [];
  List<BarberModel> _barberList = [];
  List<PembayaranModel> _pembayaranList = [];
  List<ReservasiModel> _historyList = [];
  bool _isLoading = false;

  // Getters
  List<LayananModel> get layananList => _layananList;
  List<BarberModel> get barberList => _barberList;
  List<PembayaranModel> get pembayaranList => _pembayaranList;
  List<ReservasiModel> get historyList => _historyList;
  bool get isLoading => _isLoading;

  // 1. LOAD DATA UMUM
  Future<void> loadInitialData() async {
    _isLoading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _dbService.getLayananList(),
        _dbService.getBarberList(),
      ]);
      _layananList = results[0] as List<LayananModel>;
      _barberList = results[1] as List<BarberModel>;
    } catch (e) {
      debugPrint("Error loading data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper untuk get User by ID
  Future<UserModel> getUserById(String id) async {
    return await _dbService.getUserById(id);
  }

  // 2. SUBMIT BOOKING
  Future<String?> submitBooking({
    required String idUser,
    required String namaPemesan,
    required DateTime tanggal,
    required String waktuMulai,
    required String idBarber,
    required String idLayanan,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Cari durasi layanan
      final layanan = _layananList.firstWhere(
        (l) => l.id == idLayanan,
        orElse: () => LayananModel(id: '', namaLayanan: '', harga: 0, durasiMenit: 30), // Default 30 jika not found
      );

      final newReservasi = await _dbService.createReservasi(
        idUser: idUser,
        namaPemesan: namaPemesan,
        tanggal: tanggal,
        waktuMulai: waktuMulai,
        idBarber: idBarber,
        idLayanan: idLayanan,
        durasiMenit: layanan.durasiMenit, // Kirim Durasi Asli
      );
      return newReservasi.id;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 3. SUBMIT PEMBAYARAN
  Future<void> submitPembayaran({
    required String idReservasi,
    required int jumlahBayar,
    PlatformFile? fileGambar, // Optional
    required String metode,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      String fileId = "";
      
      // Hanya upload jika ada file gambar
      if (fileGambar != null) {
        fileId = await _storageService.uploadBuktiBayar(fileGambar);
      }
      
      await _dbService.createPembayaran(
        idReservasi: idReservasi,
        jumlahBayar: jumlahBayar,
        fileId: fileId,
        metodePembayaran: metode,
      );
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 4. ADMIN FEATURES: Load Data Pembayaran
  Future<void> loadPembayaranList() async {
    _isLoading = true;
    notifyListeners();
    try {
      _pembayaranList = await _dbService.getPembayaranList();
    } catch (e) {
      debugPrint("Error load pembayaran: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- LOGIKA BARU: SINKRONISASI STATUS ---
  Future<void> verifyPembayaran(String idPembayaran, bool isAccepted) async {
    _isLoading = true;
    notifyListeners();
    try {
      // 1. Cari data pembayaran dulu untuk cek metode
      final pembayaranTarget = _pembayaranList.firstWhere((e) => e.id == idPembayaran);
      final isCOD = pembayaranTarget.metode.contains('Ditempat') || pembayaranTarget.metode.contains('COD');

      // 2. Tentukan status baru
      String statusBayar;
      String statusReservasi;

      if (isAccepted) {
        statusReservasi = 'Confirmed'; // Slot aman
        // Jika COD, uang belum masuk -> Belum Lunas
        // Jika Transfer, uang sudah masuk -> Lunas
        statusBayar = isCOD ? 'Belum Lunas' : 'Lunas';
      } else {
        statusReservasi = 'Dibatalkan';
        statusBayar = 'Ditolak';
      }

      // 3. Update status di tabel Pembayaran
      await _dbService.updateStatusPembayaran(idPembayaran, statusBayar);

      // 4. Update status di tabel Reservasi (Agar user tahu bookingnya confirmed)
      try {
        final reservasiAsli = await _dbService.getReservasiById(pembayaranTarget.idReservasi);
        await _dbService.updateStatusReservasi(
          pembayaranTarget.idReservasi, 
          statusReservasi,
          nomorAntrian: reservasiAsli.nomorAntrian,
          waktuBooking: reservasiAsli.waktuBooking.toIso8601String(),
          estimasiWaktuSelesai: reservasiAsli.estimasiWaktuSelesai?.toIso8601String(),
        );
      } catch (e) {
        print("Gagal update reservasi (mungkin sudah dihapus): $e");
      }

      // 5. Refresh list pembayaran admin
      await loadPembayaranList();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 5. CLIENT HISTORY
  Future<void> loadUserHistory(String idUser) async {
    _isLoading = true;
    notifyListeners();
    try {
      if (_layananList.isEmpty) await loadInitialData(); 
      _historyList = await _dbService.getReservasiByUser(idUser);
    } catch (e) {
      debugPrint("Error load history: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 6. CEK JADWAL (Untuk validasi bentrok)
  Future<List<ReservasiModel>> getBookingsByBarberAndDate(String idBarber, DateTime date) async {
    return await _dbService.getReservasiByBarberAndDate(idBarber, date);
  }

  // Ambil detail reservasi (untuk validasi pembayaran)
  Future<ReservasiModel> getReservasiById(String id) async {
    return await _dbService.getReservasiById(id);
  }

  // 7. FINANCIAL REPORT LOGIC
  
  // Total Pendapatan (Semua Waktu)
  int get totalRevenue {
    return _pembayaranList
        .where((p) => p.status.toLowerCase() == 'lunas')
        .fold(0, (sum, item) => sum + item.jumlahBayar);
  }

  // Pendapatan Hari Ini
  int get todayRevenue {
    final now = DateTime.now();
    return _pembayaranList
        .where((p) => 
            p.status.toLowerCase() == 'lunas' && 
            _isSameDay(p.createdAt, now))
        .fold(0, (sum, item) => sum + item.jumlahBayar);
  }

  // Pendapatan Bulan Ini
  int get monthRevenue {
    final now = DateTime.now();
    return _pembayaranList
        .where((p) => 
            p.status.toLowerCase() == 'lunas' && 
            p.createdAt.month == now.month && 
            p.createdAt.year == now.year)
        .fold(0, (sum, item) => sum + item.jumlahBayar);
  }

  // Data Grafik (7 Hari Terakhir)
  Map<DateTime, int> getDailyRevenueData() {
    final Map<DateTime, int> data = {};
    final now = DateTime.now();
    
    // Inisialisasi 7 hari terakhir dengan 0
    for (int i = 6; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      data[date] = 0;
    }

    // Isi dengan data real
    for (var payment in _pembayaranList) {
      if (payment.status.toLowerCase() == 'lunas') {
        final paymentDate = DateTime(payment.createdAt.year, payment.createdAt.month, payment.createdAt.day);
        if (data.containsKey(paymentDate)) {
          data[paymentDate] = (data[paymentDate] ?? 0) + payment.jumlahBayar;
        }
      }
    }
    return data;
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  // Helper Methods
  String getNamaLayanan(String id) {
    try {
      return _layananList.firstWhere((e) => e.id == id).namaLayanan;
    } catch (e) { return 'Layanan Tidak Dikenal'; }
  }

  String getNamaBarber(String id) {
    try {
      return _barberList.firstWhere((e) => e.id == id).namaBarber;
    } catch (e) { return 'Barber Tidak Dikenal'; }
  }

  int getHargaLayanan(String id) {
    try {
      return _layananList.firstWhere((e) => e.id == id).harga;
    } catch (e) { return 0; }
  }

  // CRUD Helpers
  Future<void> addLayanan(String n, int h, int d) async { await _dbService.addLayanan(namaLayanan: n, harga: h, durasi: d); await loadInitialData(); notifyListeners(); }
  Future<void> updateLayanan(String id, String n, int h, int d) async { await _dbService.updateLayanan(id: id, namaLayanan: n, harga: h, durasi: d); await loadInitialData(); notifyListeners(); }
  Future<void> deleteLayanan(String id) async { await _dbService.deleteLayanan(id); await loadInitialData(); notifyListeners(); }
  Future<void> addBarber(String n, String s, String st) async { await _dbService.addBarber(nama: n, spesialisasi: s, status: st); await loadInitialData(); notifyListeners(); }
  Future<void> updateBarber(String id, String n, String s, String st) async { await _dbService.updateBarber(id: id, nama: n, spesialisasi: s, status: st); await loadInitialData(); notifyListeners(); }
  Future<void> deleteBarber(String id) async { await _dbService.deleteBarber(id); await loadInitialData(); notifyListeners(); }
}