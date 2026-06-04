import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as model;
import '../../config/app_constants.dart';
import '../models/user_model.dart';
import 'appwrite_client.dart';

class AuthService {
  final AppwriteClient _appwrite = AppwriteClient();

  // 1. REGISTER (Daftar Akun Baru)
  Future<UserModel> register({
    required String email,
    required String password,
    required String nama,
    required String telepon,
  }) async {
    try {
      // Tahap A: Buat Akun di Appwrite Auth
      final result = await _appwrite.account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: nama,
      );

      // Tahap B: Simpan data tambahan ke Database Collection 'Users'
      // Kita set default role sebagai 'pelanggan'
      await _appwrite.databases.createDocument(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.collectionUsers,
        documentId: result.$id, // Gunakan ID yang sama dengan Auth
        data: {
          'nama': nama,
          'email': email,
          'telepon': telepon,
          'role': 'pelanggan', // Default role
        },
      );

      // Tahap C: Langsung Login setelah daftar
      await login(email: email, password: password);

      return UserModel(
        id: result.$id,
        nama: nama,
        email: email,
        telepon: telepon,
        role: 'pelanggan',
      );
    } catch (e) {
      rethrow; // Lempar error agar bisa ditampilkan di UI
    }
  }

  // 2. LOGIN (Masuk)
  Future<model.Session> login({
    required String email,
    required String password,
  }) async {
    try {
      return await _appwrite.account.createEmailPasswordSession(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // 3. LOGOUT (Keluar)
  Future<void> logout() async {
    try {
      await _appwrite.account.deleteSession(sessionId: 'current');
    } catch (e) {
      rethrow;
    }
  }

  // 4. GET CURRENT USER (Cek Siapa yang Login)
  Future<UserModel?> getCurrentUser() async {
    try {
      // Ambil data akun dari Auth
      final userAccount = await _appwrite.account.get();

      // Ambil detail tambahan (role) dari Database Users
      final userDoc = await _appwrite.databases.getDocument(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.collectionUsers,
        documentId: userAccount.$id,
      );

      // Gabungkan menjadi UserModel
      return UserModel.fromJson(userDoc.data, userDoc.$id);
    } catch (e) {
      return null; // Tidak ada user login
    }
  }

  // 5. UPDATE PROFIL (Nama & Telepon)
  Future<void> updateProfile({required String userId, required String nama, required String telepon}) async {
    try {
      // 1. Update Nama di Auth Account
      try {
        await _appwrite.account.updateName(name: nama);
      } catch (e) {
        print("WARN: Gagal update nama di Auth: $e");
        // Kita lanjut ke update database karena mungkin nama di DB lebih penting untuk aplikasi kita
      }

      // 2. Update Data di Database Collection Users
      await _appwrite.databases.updateDocument(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.collectionUsers,
        documentId: userId,
        data: {
          'nama': nama,
          'telepon': telepon,
        },
      );
    } catch (e) {
      print("ERROR: Gagal update profil di Database: $e");
      throw Exception("Gagal menyimpan profil: $e");
    }
  }

  // 6. UPDATE EMAIL
  Future<void> updateEmail({required String email, required String password}) async {
    try {
      await _appwrite.account.updateEmail(email: email, password: password);
      // Note: Update email di database mungkin perlu dilakukan manual atau via function, 
      // tapi untuk simplifikasi kita asumsikan user harus verifikasi dulu.
      // Di sini kita update database juga agar sync.
      final user = await _appwrite.account.get();
      await _appwrite.databases.updateDocument(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.collectionUsers,
        documentId: user.$id,
        data: {'email': email},
      );
    } catch (e) {
      rethrow;
    }
  }

  // 7. UPDATE PASSWORD
  Future<void> updatePassword({required String newPassword, required String oldPassword}) async {
    try {
      await _appwrite.account.updatePassword(password: newPassword, oldPassword: oldPassword);
    } catch (e) {
      rethrow;
    }
  }
}