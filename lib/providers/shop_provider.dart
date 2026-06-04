import 'package:flutter/foundation.dart';
import '../data/services/database_service.dart';

class ShopProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  
  String _status = 'buka'; // 'buka', 'istirahat', 'tutup'
  DateTime? _breakStartTime;
  DateTime? _breakEndTime;
  DateTime? _openTime;
  bool _isLoading = false;

  String get status => _status;
  DateTime? get breakStartTime => _breakStartTime;
  DateTime? get breakEndTime => _breakEndTime;
  DateTime? get openTime => _openTime;
  bool get isLoading => _isLoading;

  Future<void> loadShopStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _dbService.getShopStatus();
      _status = data['status'] ?? 'buka';
      // Note: Logic break time dan open time sementara diabaikan untuk simplifikasi
      // karena butuh field tambahan di database. Fokus ke Buka/Tutup dulu.
    } catch (e) {
      print("Error loading shop status: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateShopStatus({
    required String status,
    DateTime? breakStart,
    DateTime? breakEnd,
    DateTime? openTime,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _dbService.updateShopStatusGlobal(status);
      _status = status;
      _breakStartTime = breakStart;
      _breakEndTime = breakEnd;
      _openTime = openTime;
    } catch (e) {
      print("Error update shop status: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isShopOpen() {
    return _status.toLowerCase() == 'buka';
  }
}