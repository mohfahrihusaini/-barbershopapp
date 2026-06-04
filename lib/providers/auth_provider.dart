import 'package:flutter/material.dart';
import '../data/models/user_model.dart';
import '../data/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  // State (Data yang disimpan)
  UserModel? _currentUser;
  bool _isLoading = false;

  // Getters (Cara mengambil data dari luar)
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  // 1. CEK SESI (Dipanggil saat aplikasi baru dibuka)
  Future<void> checkSession() async {
    _setLoading(true);
    try {
      final user = await _authService.getCurrentUser();
      _currentUser = user;
    } catch (e) {
      // Jika gagal/tidak ada sesi, berarti belum login
      _currentUser = null;
    } finally {
      _setLoading(false);
    }
  }

  // 2. LOGIN
  Future<void> login({required String email, required String password}) async {
    _setLoading(true);
    try {
      // Login ke Appwrite
      await _authService.login(email: email, password: password);
      
      // Ambil detail user setelah berhasil login
      _currentUser = await _authService.getCurrentUser();
      
      notifyListeners(); // Beritahu UI bahwa data user sudah ada
    } catch (e) {
      rethrow; // Lempar error agar bisa ditangkap UI (untuk Snackbar)
    } finally {
      _setLoading(false);
    }
  }

  // 3. REGISTER
  Future<void> register({
    required String email,
    required String password,
    required String nama,
    required String telepon,
  }) async {
    _setLoading(true);
    try {
      // Daftar dan langsung dapatkan data user
      final newUser = await _authService.register(
        email: email,
        password: password,
        nama: nama,
        telepon: telepon,
      );
      
      _currentUser = newUser;
      notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // 4. LOGOUT
  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.logout();
      _currentUser = null;
      notifyListeners(); // Beritahu UI untuk kembali ke halaman login
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // 5. UPDATE PROFIL
  Future<void> updateProfile({required String nama, required String telepon}) async {
    if (_currentUser == null) return;
    _setLoading(true);
    try {
      await _authService.updateProfile(userId: _currentUser!.id, nama: nama, telepon: telepon);
      
      // Ambil data terbaru dari server untuk memastikan sinkronisasi
      final updatedUser = await _authService.getCurrentUser();
      if (updatedUser != null) {
        _currentUser = updatedUser;
      }
      notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // 6. UPDATE EMAIL
  Future<void> updateEmail({required String email, required String password}) async {
    _setLoading(true);
    try {
      await _authService.updateEmail(email: email, password: password);
      // Update local state
      if (_currentUser != null) {
        _currentUser = UserModel(
          id: _currentUser!.id,
          nama: _currentUser!.nama,
          email: email,
          telepon: _currentUser!.telepon,
          role: _currentUser!.role,
        );
      }
      notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // 7. UPDATE PASSWORD
  Future<void> updatePassword({required String newPassword, required String oldPassword}) async {
    _setLoading(true);
    try {
      await _authService.updatePassword(newPassword: newPassword, oldPassword: oldPassword);
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Helper untuk mengubah status loading
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}