import 'package:flutter/material.dart';
import 'dart:async';
import '../data/models/reservasi_model.dart';
import '../data/services/database_service.dart';

class QueueProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  
  List<ReservasiModel> _currentQueue = [];
  bool _isLoading = false;
  String? _error;
  Timer? _statusCheckerTimer;
  DateTime _selectedDate = DateTime.now();

  List<ReservasiModel> get currentQueue => _currentQueue;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime get selectedDate => _selectedDate;

  QueueProvider() {
    // Jalankan pengecekan setiap 1 menit
    _statusCheckerTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkAndAutoUpdateStatus();
    });
  }

  void updateDate(DateTime date) {
    _selectedDate = date;
    loadQueue();
  }

  @override
  void dispose() {
    _statusCheckerTimer?.cancel();
    super.dispose();
  }

  // LOGIKA OTOMATISASI STATUS
  Future<void> _checkAndAutoUpdateStatus() async {
    if (_currentQueue.isEmpty) return;

    final now = DateTime.now();
    bool needsReload = false;

    for (var reservation in _currentQueue) {
      // 1. MENUNGGU -> SEDANG DILAYANI
      // Jika waktu sekarang sudah melewati waktu mulai reservasi
      if ((reservation.statusAntrian == 'Menunggu' || reservation.statusAntrian == 'Confirmed') &&
          now.isAfter(reservation.startDateTime)) {
        
        // Cek apakah kapster sedang melayani orang lain?
        // Untuk simplifikasi, kita anggap jika waktunya tiba, dia mulai dilayani.
        // Update ke database
        await _dbService.updateStatusReservasi(
          reservation.id, 
          'Sedang Dilayani', 
          nomorAntrian: reservation.nomorAntrian,
          waktuBooking: reservation.waktuBooking.toIso8601String(),
          estimasiWaktuSelesai: reservation.estimasiWaktuSelesai?.toIso8601String(),
        );
        needsReload = true;
        print("Auto-start reservasi ${reservation.id} - ${reservation.namaPemesan}");
      }

      // 2. SEDANG DILAYANI -> SELESAI
      // SAYA NONAKTIFKAN FITUR INI AGAR ANTRIAN TIDAK HILANG TIBA-TIBA
      // Biarkan Admin yang menekan tombol "Selesai" secara manual agar lebih akurat.
      /*
      if (reservation.statusAntrian == 'Sedang Dilayani') {
        // Gunakan estimasi yang tersimpan, atau default 30 menit dari mulai
        final endTime = reservation.estimasiWaktuSelesai ?? 
                        reservation.startDateTime.add(const Duration(minutes: 30));
        
        if (now.isAfter(endTime)) {
          await _dbService.updateStatusReservasi(reservation.id, 'Selesai');
          needsReload = true;
          print("Auto-finish reservasi ${reservation.id} - ${reservation.namaPemesan}");
        }
      }
      */
    }

    if (needsReload) {
      loadQueue();
    }
  }

  // Initial dummy data for development/visualization if backend is empty
  // TODO: Remove this when backend is fully connected
  void _loadDummyData() {
    final now = DateTime.now();
    _currentQueue = [
      ReservasiModel(
        id: '1',
        tanggal: now,
        waktuMulai: '10:00',
        statusAntrian: 'Sedang Dilayani',
        idUser: 'user1',
        idBarber: 'barber1',
        idLayanan: 'service1',
        namaPemesan: 'Andi Saputra',
        nomorAntrian: 1,
        waktuBooking: now.subtract(const Duration(minutes: 30)),
        estimasiWaktuSelesai: now.add(const Duration(minutes: 15)),
      ),
      ReservasiModel(
        id: '2',
        tanggal: now,
        waktuMulai: '10:45',
        statusAntrian: 'Menunggu',
        idUser: 'user2',
        idBarber: 'barber2',
        idLayanan: 'service2',
        namaPemesan: 'Budi Santoso',
        nomorAntrian: 2,
        waktuBooking: now.subtract(const Duration(minutes: 15)),
        estimasiWaktuSelesai: now.add(const Duration(minutes: 60)),
      ),
      ReservasiModel(
        id: '3',
        tanggal: now,
        waktuMulai: '11:30',
        statusAntrian: 'Menunggu',
        idUser: 'user3',
        idBarber: 'barber1',
        idLayanan: 'service1',
        namaPemesan: 'Citra Dewi',
        nomorAntrian: 3,
        waktuBooking: now.subtract(const Duration(minutes: 5)),
        estimasiWaktuSelesai: now.add(const Duration(minutes: 105)),
      ),
    ];
    notifyListeners();
  }

  Future<void> loadQueue() async {
    _setLoading(true);
    try {
      _currentQueue = await _dbService.getQueueByDate(_selectedDate);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateReservationStatus(String id, String newStatus) async {
    try {
      // Optimistic update
      final index = _currentQueue.indexWhere((q) => q.id == id);
      if (index != -1) {
        final oldItem = _currentQueue[index];
        _currentQueue[index] = ReservasiModel(
          id: oldItem.id,
          tanggal: oldItem.tanggal,
          waktuMulai: oldItem.waktuMulai,
          statusAntrian: newStatus,
          idUser: oldItem.idUser,
          idBarber: oldItem.idBarber,
          idLayanan: oldItem.idLayanan,
          namaPemesan: oldItem.namaPemesan,
          nomorAntrian: oldItem.nomorAntrian,
          waktuBooking: oldItem.waktuBooking,
          estimasiWaktuSelesai: oldItem.estimasiWaktuSelesai,
        );
        notifyListeners();
      }

      // Update in database
      // Kita kirim semua atribut required untuk jaga-jaga
      int? nomorAntrianToSend;
      String? waktuBookingToSend;
      String? estimasiSelesaiToSend;

      if (index != -1) {
        final item = _currentQueue[index];
        nomorAntrianToSend = item.nomorAntrian;
        waktuBookingToSend = item.waktuBooking.toIso8601String();
        estimasiSelesaiToSend = item.estimasiWaktuSelesai?.toIso8601String();
      }
      
      await _dbService.updateStatusReservasi(
        id, 
        newStatus, 
        nomorAntrian: nomorAntrianToSend,
        waktuBooking: waktuBookingToSend,
        estimasiWaktuSelesai: estimasiSelesaiToSend,
      );
      
      // Reload queue to ensure consistency
      loadQueue();
      return true;
    } catch (e) {
      _error = e.toString();
      // Revert optimistic update if needed
      loadQueue();
      return false;
    }
  }

  Future<void> deleteQueueItem(String id) async {
    try {
      await _dbService.deleteReservasi(id);
      loadQueue();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> serveNextCustomer() async {
    // Logic to find the next 'Menunggu' or 'Confirmed' customer and update to 'Sedang Dilayani'
    try {
      // Cari yang statusnya Menunggu atau Confirmed
      final nextCustomerIndex = _currentQueue.indexWhere((q) => 
        q.statusAntrian == 'Menunggu' || q.statusAntrian == 'Confirmed'
      );
      
      if (nextCustomerIndex != -1) {
        final nextCustomer = _currentQueue[nextCustomerIndex];
        await updateReservationStatus(nextCustomer.id, 'Sedang Dilayani');
      }
    } catch (e) {
      _error = e.toString();
    }
  }

  // --- CLIENT FEATURES ---
  List<ReservasiModel> getUserQueue(String userId) {
    return _currentQueue.where((q) => 
      q.idUser == userId && 
      (q.statusAntrian == 'Menunggu' || q.statusAntrian == 'Confirmed' || q.statusAntrian == 'Sedang Dilayani')
    ).toList();
  }

  int getUserQueueCount(String userId) {
    return getUserQueue(userId).length;
  }
  
  // Cek apakah giliran user sudah dekat (Urutan ke-1 atau ke-2)
  bool checkUserTurn(String userId) {
    if (_currentQueue.isEmpty) return false;

    // 1. Ambil list antrian aktif global
    final activeGlobalList = _currentQueue.where((r) => 
      ['Menunggu', 'Confirmed', 'Sedang Dilayani'].contains(r.statusAntrian)
    ).toList();

    // 2. Urutkan berdasarkan waktu
    activeGlobalList.sort((a, b) {
      int timeComparison = a.startDateTime.compareTo(b.startDateTime);
      if (timeComparison == 0) return a.waktuBooking.compareTo(b.waktuBooking);
      return timeComparison;
    });

    // 3. Cari index user pertama di list (Antrian terdepan milik user)
    final myIndex = activeGlobalList.indexWhere((q) => q.idUser == userId);

    // Jika user tidak ada di antrian, return false
    if (myIndex == -1) return false;

    // Jika user berada di posisi 0 (Sedang Dilayani/Paling Depan) atau 1 (Menunggu Giliran Kedua)
    // Maka return true untuk memicu notifikasi
    return myIndex <= 1;
  }

  // Hitung berapa orang lagi di depan saya
  int getPeopleAhead(String userId) {
    if (_currentQueue.isEmpty) return 0;
    
    final activeGlobalList = _currentQueue.where((r) => 
      ['Menunggu', 'Confirmed', 'Sedang Dilayani'].contains(r.statusAntrian)
    ).toList();
    
    activeGlobalList.sort((a, b) {
      int timeComparison = a.startDateTime.compareTo(b.startDateTime);
      if (timeComparison == 0) return a.waktuBooking.compareTo(b.waktuBooking);
      return timeComparison;
    });

    final myIndex = activeGlobalList.indexWhere((q) => q.idUser == userId);
    if (myIndex == -1) return 0;
    
    return myIndex; // Jika saya di index 2, berarti ada 2 orang di depan (0, 1)
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}