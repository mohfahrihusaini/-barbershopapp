import 'package:appwrite/appwrite.dart';
import '../../config/app_constants.dart';
import '../models/barber_model.dart';
import '../models/layanan_model.dart';
import '../models/reservasi_model.dart';
import '../models/pembayaran_model.dart';
import '../models/user_model.dart'; // Import UserModel
import 'appwrite_client.dart';

class DatabaseService {
  final AppwriteClient _appwrite = AppwriteClient();

  // ==================== USER ====================
  Future<UserModel> getUserById(String id) async {
    try {
      final doc = await _appwrite.databases.getDocument(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.collectionUsers,
        documentId: id,
      );
      return UserModel.fromJson(doc.data, doc.$id);
    } catch (e) {
      throw Exception('Gagal mengambil data user: $e');
    }
  }

  // ==================== LAYANAN ====================
  Future<List<LayananModel>> getLayananList() async {
    try {
      final response = await _appwrite.databases.listDocuments(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.collectionLayanan,
      );
      return response.documents.map((doc) => LayananModel.fromJson(doc.data)).toList();
    } catch (e) {
      throw Exception('Gagal memuat layanan: $e');
    }
  }

  Future<void> addLayanan({required String namaLayanan, required int harga, required int durasi}) async {
    await _appwrite.databases.createDocument(
      databaseId: AppConstants.databaseId,
      collectionId: AppConstants.collectionLayanan,
      documentId: ID.unique(),
      data: {'nama_layanan': namaLayanan, 'harga': harga, 'durasi_menit': durasi},
    );
  }

  Future<void> updateLayanan({required String id, required String namaLayanan, required int harga, required int durasi}) async {
    await _appwrite.databases.updateDocument(
      databaseId: AppConstants.databaseId,
      collectionId: AppConstants.collectionLayanan,
      documentId: id,
      data: {'nama_layanan': namaLayanan, 'harga': harga, 'durasi_menit': durasi},
    );
  }

  Future<void> deleteLayanan(String id) async {
    await _appwrite.databases.deleteDocument(
      databaseId: AppConstants.databaseId,
      collectionId: AppConstants.collectionLayanan,
      documentId: id,
    );
  }

  // ==================== BARBER ====================
  Future<List<BarberModel>> getBarberList() async {
    try {
      final response = await _appwrite.databases.listDocuments(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.collectionBarber,
      );
      return response.documents.map((doc) => BarberModel.fromJson(doc.data)).toList();
    } catch (e) {
      throw Exception('Gagal memuat barber: $e');
    }
  }

  Future<void> addBarber({required String nama, required String spesialisasi, required String status}) async {
    try {
      await _appwrite.databases.createDocument(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.collectionBarber,
        documentId: ID.unique(),
        data: {'nama_barber': nama, 'spesialisasi': spesialisasi, 'status': status},
      );
    } catch (e) {
      print("Error addBarber: $e");
      rethrow;
    }
  }

  Future<void> updateBarber({required String id, required String nama, required String spesialisasi, required String status}) async {
    await _appwrite.databases.updateDocument(
      databaseId: AppConstants.databaseId,
      collectionId: AppConstants.collectionBarber,
      documentId: id,
      data: {'nama_barber': nama, 'spesialisasi': spesialisasi, 'status': status},
    );
  }

  Future<void> deleteBarber(String id) async {
    await _appwrite.databases.deleteDocument(
      databaseId: AppConstants.databaseId,
      collectionId: AppConstants.collectionBarber,
      documentId: id,
    );
  }

  // ==================== RESERVASI ====================
  Future<ReservasiModel> createReservasi({
    required String idUser,
    required String namaPemesan,
    required DateTime tanggal,
    required String waktuMulai,
    required String idBarber,
    required String idLayanan,
    required int durasiMenit, // Parameter Baru
  }) async {
    // 1. Hitung jumlah antrian pada tanggal tersebut untuk mendapatkan nomor antrian berikutnya
    int nextQueueNumber = 1;
    try {
      final startOfDay = DateTime(tanggal.year, tanggal.month, tanggal.day).toIso8601String();
      final endOfDay = DateTime(tanggal.year, tanggal.month, tanggal.day, 23, 59, 59).toIso8601String();
      
      final existingReservations = await _appwrite.databases.listDocuments(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.collectionReservasi,
        queries: [
          Query.greaterThanEqual('tanggal', startOfDay),
          Query.lessThanEqual('tanggal', endOfDay),
        ],
      );
      // Nomor antrian = jumlah dokumen + 1
      nextQueueNumber = existingReservations.total + 1;
    } catch (e) {
      print("Gagal menghitung nomor antrian: $e");
      // Fallback ke 1 jika gagal, atau bisa rethrow
    }

    // Hitung Estimasi Waktu Selesai Berdasarkan Durasi Layanan
    DateTime? estimasiSelesai;
    try {
      final parts = waktuMulai.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      // Gabungkan tanggal dengan jam dari waktuMulai
      final jadwalMulai = DateTime(tanggal.year, tanggal.month, tanggal.day, hour, minute);
      
      // Gunakan durasiMenit dari parameter
      estimasiSelesai = jadwalMulai.add(Duration(minutes: durasiMenit));
    } catch (_) {
      // Fallback jika parsing gagal
      estimasiSelesai = tanggal.add(Duration(minutes: durasiMenit));
    }

    // 2. Buat dokumen reservasi baru dengan nomor antrian
    final result = await _appwrite.databases.createDocument(
      databaseId: AppConstants.databaseId,
      collectionId: AppConstants.collectionReservasi,
      documentId: ID.unique(),
      data: {
        'tanggal': tanggal.toIso8601String(),
        'waktu_mulai': waktuMulai,
        'status_antrian': 'Menunggu',
        'id_user': idUser,
        'id_barber': idBarber,
        'id_layanan': idLayanan,
        'nama_pemesan': namaPemesan,
        'nomor_antrian': nextQueueNumber,
        'waktu_booking': DateTime.now().toIso8601String(),
        'estimasi_waktu_selesai': estimasiSelesai.toIso8601String(),
      },
    );
    return ReservasiModel.fromJson(result.data);
  }

  Future<List<ReservasiModel>> getReservasiByUser(String idUser) async {
    try {
      final response = await _appwrite.databases.listDocuments(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.collectionReservasi,
        queries: [
          Query.equal('id_user', idUser),
          Query.orderDesc('\$createdAt'),
        ],
      );
      return response.documents.map((doc) => ReservasiModel.fromJson(doc.data)).toList();
    } catch (e) {
      throw Exception('Gagal memuat history: $e');
    }
  }

  // --- BARU: Ambil Reservasi by ID (Untuk helper validasi) ---
  Future<ReservasiModel> getReservasiById(String idReservasi) async {
    try {
      final response = await _appwrite.databases.getDocument(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.collectionReservasi,
        documentId: idReservasi,
      );
      return ReservasiModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Gagal mengambil reservasi: $e');
    }
  }

  // Ambil reservasi berdasarkan Barber dan Tanggal (untuk cek bentrok)
  Future<List<ReservasiModel>> getReservasiByBarberAndDate(String idBarber, DateTime date) async {
    // Filter tanggal mulai dari 00:00:00 sampai 23:59:59
    final startOfDay = DateTime(date.year, date.month, date.day).toIso8601String();
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();

    try {
      final response = await _appwrite.databases.listDocuments(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.collectionReservasi,
        queries: [
          Query.equal('id_barber', idBarber),
          Query.greaterThanEqual('tanggal', startOfDay),
          Query.lessThanEqual('tanggal', endOfDay),
        ],
      );
      return response.documents.map((doc) => ReservasiModel.fromJson(doc.data)).toList();
    } catch (e) {
      // Jika index belum dibuat, kembalikan list kosong agar tidak error fatal (sementara)
      return [];
    }
  }

  // --- BARU: Update Status Reservasi (Dipanggil saat lunas) ---
  Future<void> updateStatusReservasi(
    String idReservasi, 
    String statusBaru, 
    {
      int? nomorAntrian,
      String? waktuBooking,
      String? estimasiWaktuSelesai,
    }
  ) async {
    try {
      final Map<String, dynamic> data = {
        'status_antrian': statusBaru,
      };
      
      // Sertakan atribut wajib (Required)
      // Jika null, kita PAKSA isi dengan default agar tidak error "Missing required attribute"
      
      data['nomor_antrian'] = nomorAntrian ?? 0;
      data['waktu_booking'] = waktuBooking ?? DateTime.now().toIso8601String();
      data['estimasi_waktu_selesai'] = estimasiWaktuSelesai ?? DateTime.now().add(const Duration(minutes: 30)).toIso8601String();

      await _appwrite.databases.updateDocument(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.collectionReservasi,
        documentId: idReservasi,
        data: data,
      );
    } catch (e) {
      throw Exception('Gagal update status reservasi: $e');
    }
  }

  // --- BARU: Hapus Reservasi (Untuk bersih-bersih antrian selesai) ---
  Future<void> deleteReservasi(String idReservasi) async {
    try {
      await _appwrite.databases.deleteDocument(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.collectionReservasi,
        documentId: idReservasi,
      );
    } catch (e) {
      throw Exception('Gagal menghapus reservasi: $e');
    }
  }

  // ==================== PEMBAYARAN ====================
  Future<void> createPembayaran({
    required String idReservasi,
    required int jumlahBayar,
    required String fileId, // Bisa string kosong jika tidak ada file
    required String metodePembayaran,
  }) async {
    String? buktiUrl;
    
    if (fileId.isNotEmpty) {
      buktiUrl = "${AppConstants.endpoint}/storage/buckets/${AppConstants.bucketBuktiBayar}/files/$fileId/view?project=${AppConstants.projectId}";
    }

    await _appwrite.databases.createDocument(
      databaseId: AppConstants.databaseId,
      collectionId: AppConstants.collectionPembayaran,
      documentId: ID.unique(),
      data: {
        'id_reservasi': idReservasi,
        'jumlah_bayar': jumlahBayar,
        'bukti_bayar': buktiUrl, // Bisa null
        'status_verifikasi': 'Pending',
        'metode_pembayaran': metodePembayaran,
      },
    );
  }

  Future<List<PembayaranModel>> getPembayaranList() async {
    final response = await _appwrite.databases.listDocuments(
      databaseId: AppConstants.databaseId,
      collectionId: AppConstants.collectionPembayaran,
      queries: [
        Query.orderDesc('\$createdAt'),
        Query.limit(100), // Tingkatkan limit agar laporan lebih lengkap
      ],
    );
    return response.documents.map((doc) => PembayaranModel.fromJson(doc.data)).toList();
  }

  // --- BARU: Ambil Pembayaran berdasarkan Rentang Tanggal ---
  Future<List<PembayaranModel>> getPembayaranByDateRange(DateTime start, DateTime end) async {
    try {
      final response = await _appwrite.databases.listDocuments(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.collectionPembayaran,
        queries: [
          Query.greaterThanEqual('\$createdAt', start.toIso8601String()),
          Query.lessThanEqual('\$createdAt', end.toIso8601String()),
          Query.orderDesc('\$createdAt'),
          Query.limit(500), // Limit cukup besar untuk laporan
        ],
      );
      return response.documents.map((doc) => PembayaranModel.fromJson(doc.data)).toList();
    } catch (e) {
      print("Error getPembayaranByDateRange: $e");
      return [];
    }
  }

  // --- BARU: Cari Pembayaran by Reservasi ID ---
  Future<PembayaranModel?> getPembayaranByReservasiId(String idReservasi) async {
    try {
      final response = await _appwrite.databases.listDocuments(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.collectionPembayaran,
        queries: [
          Query.equal('id_reservasi', idReservasi),
          Query.limit(1),
        ],
      );
      if (response.documents.isNotEmpty) {
        return PembayaranModel.fromJson(response.documents.first.data);
      }
      return null;
    } catch (e) {
      print("Error getPembayaranByReservasiId: $e");
      return null;
    }
  }

  Future<void> updateStatusPembayaran(String idPembayaran, String statusBaru) async {
    await _appwrite.databases.updateDocument(
      databaseId: AppConstants.databaseId,
      collectionId: AppConstants.collectionPembayaran,
      documentId: idPembayaran,
      data: {'status_verifikasi': statusBaru},
    );
  }

  // ==================== ANTRIAN (QUEUE) ====================
  Future<List<ReservasiModel>> getQueueToday() async {
    return getQueueByDate(DateTime.now());
  }

  Future<List<ReservasiModel>> getQueueByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day).toIso8601String();
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();

    try {
      // Ambil semua reservasi pada tanggal tersebut
      final response = await _appwrite.databases.listDocuments(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.collectionReservasi,
        queries: [
          Query.greaterThanEqual('tanggal', startOfDay),
          Query.lessThanEqual('tanggal', endOfDay),
        ],
      );
      
      final allReservations = response.documents.map((doc) => ReservasiModel.fromJson(doc.data)).toList();
      
      // Filter status yang relevan untuk antrian aktif
      return allReservations.where((r) => 
        ['Menunggu', 'Confirmed', 'Sedang Dilayani', 'Selesai'].contains(r.statusAntrian)
      ).toList();
      
    } catch (e) {
      print("Error fetching queue: $e");
      return [];
    }
  }

  // ==================== SHOP SETTINGS (GLOBAL) ====================
  // Kita menggunakan document ID khusus 'shop_settings' di dalam collection Barber
  // untuk menyimpan status toko agar bisa diakses semua user.
  
  Future<Map<String, dynamic>> getShopStatus() async {
    try {
      final doc = await _appwrite.databases.getDocument(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.collectionBarber, // Numpang di collection barber
        documentId: 'shop_settings',
      );
      return doc.data;
    } catch (e) {
      // Jika dokumen belum ada, kita buat default
      try {
        await _appwrite.databases.createDocument(
          databaseId: AppConstants.databaseId,
          collectionId: AppConstants.collectionBarber,
          documentId: 'shop_settings',
          data: {
            'nama_barber': 'SYSTEM_SETTINGS', // Penanda
            'spesialisasi': 'System',
            'status': 'buka', // Status Toko: buka, tutup, istirahat
          },
        );
        return {'status': 'buka'};
      } catch (_) {
        return {'status': 'buka'}; // Fallback
      }
    }
  }

  Future<void> updateShopStatusGlobal(String status) async {
    try {
      // Cek dulu apakah dokumen ada
      await getShopStatus(); 
      
      await _appwrite.databases.updateDocument(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.collectionBarber,
        documentId: 'shop_settings',
        data: {
          'status': status,
        },
      );
    } catch (e) {
      print("Gagal update status toko: $e");
      throw Exception("Gagal update status toko");
    }
  }

  // ==================== CHAT SYSTEM (REVISED) ====================
  
  // 1. Ambil atau Buat Chat Room untuk User tertentu (Isolasi per Pelanggan)
  Future<String> getOrCreateChatRoom(String userId, String userName) async {
    try {
      // Pastikan query mencari room spesifik milik userId ini
      final response = await _appwrite.databases.listDocuments(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.chatRoomsCollectionId,
        queries: [
          Query.equal('id_user', userId),
          Query.limit(1),
        ],
      );

      if (response.documents.isNotEmpty) {
        return response.documents.first.$id;
      } else {
        // Buat room baru yang terikat unik ke userId
        final newRoom = await _appwrite.databases.createDocument(
          databaseId: AppConstants.databaseId,
          collectionId: AppConstants.chatRoomsCollectionId,
          documentId: ID.unique(),
          data: {
            'id_user': userId,
            'username': userName,
            'lastmessage': 'Halo, ada yang bisa kami bantu?',
            'lastmessagetime': DateTime.now().toIso8601String(),
            'unread_count': 0,
            'isActive': true,
          },
        );
        return newRoom.$id;
      }
    } catch (e) {
      throw Exception('Gagal memuat chat room: $e');
    }
  }

  // 2. Ambil Daftar Pesan dalam Room dengan Isolasi Keamanan
  Future<List<Map<String, dynamic>>> getChatMessages(String roomId) async {
    try {
      final response = await _appwrite.databases.listDocuments(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.chatMessagesCollectionId,
        queries: [
          Query.equal('id_chatroom', roomId),
          Query.orderAsc('timestamp'),
          Query.limit(100), // Batasi 100 pesan terakhir
        ],
      );
      
      // Note: Filter (sender/receiver) secara teknis sudah terwakili oleh id_chatroom,
      // namun id_chatroom adalah kunci utama pemisahan room.
      return response.documents.map((doc) => doc.data).toList();
    } catch (e) {
      print("Error getChatMessages: $e");
      return [];
    }
  }

  // 3. Kirim Pesan dengan Payload Lengkap
  Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    required String receiverId, // ID Pelanggan atau 'admin'
    required String text,
    required bool isAdmin,
  }) async {
    try {
      final timestamp = DateTime.now().toIso8601String();

      // a. Simpan Pesan ke Koleksi Messages
      await _appwrite.databases.createDocument(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.chatMessagesCollectionId,
        documentId: ID.unique(),
        data: {
          'id_chatroom': roomId,
          'id_sender': senderId,
          'sender_name': senderName,
          'id_receiver': receiverId,
          'message': text,
          'timestamp': timestamp,
          'isread': false,
          'type': 'text',
        },
      );

      // b. Update Informasi Terakhir di Room
      final roomDoc = await _appwrite.databases.getDocument(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.chatRoomsCollectionId,
        documentId: roomId,
      );
      
      // Logic Unread: Tambah jika pesan dari pelanggan untuk admin
      int newUnread = roomDoc.data['unread_count'] ?? 0;
      if (!isAdmin) {
        newUnread += 1;
      }

      await _appwrite.databases.updateDocument(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.chatRoomsCollectionId,
        documentId: roomId,
        data: {
          'lastmessage': text,
          'lastmessagetime': timestamp,
          'unread_count': isAdmin ? 0 : newUnread, // Admin membalas = reset unread (opsional)
          'isActive': true,
        },
      );
    } catch (e) {
      print("CHAT_ERROR: $e");
      throw Exception('Gagal mengirim pesan: $e');
    }
  }

  // 4. Admin: Ambil Daftar Chat Room dengan Join Manual ke Data User (Dinamis)
  Future<List<Map<String, dynamic>>> getAllChatRooms() async {
    try {
      // a. Ambil daftar room chat
      final response = await _appwrite.databases.listDocuments(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.chatRoomsCollectionId,
        queries: [
          Query.orderDesc('lastmessagetime'),
        ],
      );

      List<Map<String, dynamic>> rooms = response.documents.map((doc) {
        final data = Map<String, dynamic>.from(doc.data);
        data['\$id'] = doc.$id; 
        return data;
      }).toList();

      // b. Join Manual: Ambil semua ID User yang unik dari daftar room
      final userIds = rooms.map((r) => r['id_user'] as String).toSet().toList();
      
      if (userIds.isEmpty) return [];

      // c. Fetch data user secara batch (untuk efisiensi daripada loop satu-satu)
      final usersResponse = await _appwrite.databases.listDocuments(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.collectionUsers,
        queries: [
          Query.equal('\$id', userIds),
        ],
      );

      // Map untuk akses cepat user data by ID
      final userMap = {for (var doc in usersResponse.documents) doc.$id: doc.data};

      // d. Gabungkan data user terbaru ke dalam objek room
      for (var room in rooms) {
        final userId = room['id_user'];
        if (userMap.containsKey(userId)) {
          // Gunakan nama terbaru dari tabel users
          room['display_name'] = userMap[userId]?['nama'] ?? 'Pelanggan';
        } else {
          // Fallback jika user dihapus atau tidak ditemukan
          room['display_name'] = room['username'] ?? 'Pelanggan Tidak Dikenal';
        }
      }

      return rooms;
    } catch (e) {
      print("Error getAllChatRooms with dynamic names: $e");
      return [];
    }
  }

  // 5. Tandai Chat Sudah Dibaca
  Future<void> markChatAsRead(String roomId) async {
    try {
      await _appwrite.databases.updateDocument(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.chatRoomsCollectionId,
        documentId: roomId,
        data: {'unread_count': 0},
      );
    } catch (e) {
      print("Error marking chat as read: $e");
    }
  }
}