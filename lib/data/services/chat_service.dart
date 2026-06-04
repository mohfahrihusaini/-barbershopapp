import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/foundation.dart';
import '../../config/app_constants.dart';
import '../models/chat_model.dart';
import 'appwrite_client.dart';
import 'storage_service.dart'; // Asumsi sudah ada, atau kita pakai AppwriteClient langsung

class ChatService {
  final AppwriteClient _client = AppwriteClient();
  final StorageService _storage = StorageService(); // Reuse storage service jika ada

  // ================= ROOM MANAGEMENT =================

  // Mendapatkan atau Membuat Room untuk Client tertentu
  Future<String> getOrCreateRoom(String userId, String userName) async {
    try {
      // 1. Cek apakah room sudah ada
      final existing = await _client.databases.listDocuments(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.chatRoomsCollectionId,
        queries: [
          Query.search('participants', userId), // Cari yang ada userId-nya
        ],
      );

      if (existing.documents.isNotEmpty) {
        return existing.documents.first.$id;
      }

      // 2. Jika belum ada, buat baru
      final newRoom = await _client.databases.createDocument(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.chatRoomsCollectionId,
        documentId: ID.unique(),
        data: {
          'participants': [userId, 'admin'], // 'admin' bisa diganti ID admin spesifik jika perlu
          'last_message': 'Chat dimulai',
          'last_message_time': DateTime.now().toIso8601String(),
          'unread_count': 0,
          'client_name': userName,
        },
      );
      
      return newRoom.$id;
    } catch (e) {
      throw Exception('Gagal membuat chat room: $e');
    }
  }

  // Mendapatkan List Room (Untuk Admin)
  Future<List<ChatRoom>> getAdminChatRooms() async {
    try {
      final response = await _client.databases.listDocuments(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.chatRoomsCollectionId,
        queries: [
          Query.orderDesc('last_message_time'),
        ],
      );
      
      return response.documents.map((doc) => ChatRoom.fromJson(doc.data, id: doc.$id)).toList();
    } catch (e) {
      throw Exception('Gagal memuat daftar chat: $e');
    }
  }

  // ================= MESSAGE MANAGEMENT =================

  // Mengambil history pesan
  Future<List<ChatMessage>> getMessages(String roomId) async {
    try {
      final response = await _client.databases.listDocuments(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.chatMessagesCollectionId,
        queries: [
          Query.equal('room_id', roomId),
          Query.orderDesc('timestamp'), // Terbaru diatas
          Query.limit(50), // Load 50 pesan terakhir
        ],
      );
      
      return response.documents
          .map((doc) => ChatMessage.fromJson(doc.data, id: doc.$id))
          .toList();
    } catch (e) {
      throw Exception('Gagal memuat pesan: $e');
    }
  }

  // Mengirim Pesan
  Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String content,
    MessageType type = MessageType.text,
    String? attachmentUrl,
  }) async {
    try {
      final timestamp = DateTime.now().toIso8601String();

      // 1. Simpan Pesan
      await _client.databases.createDocument(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.chatMessagesCollectionId,
        documentId: ID.unique(),
        data: {
          'room_id': roomId,
          'sender_id': senderId,
          'content': content,
          'type': type.name,
          'timestamp': timestamp,
          'is_read': false,
          'attachment_url': attachmentUrl,
        },
      );

      // 2. Update Room (Last Message)
      // Logic: Jika sender adalah admin, reset unread count client jadi 0 (karena client baca)??
      // Atau logic badge: Jika sender != admin, increment unread count for admin.
      // Sederhananya kita update last message dulu.
      
      await _client.databases.updateDocument(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.chatRoomsCollectionId,
        documentId: roomId,
        data: {
          'last_message': type == MessageType.image ? '📷 Gambar' : content,
          'last_message_time': timestamp,
          // 'unread_count': current + 1 (Butuh logic di provider atau function terpisah)
        },
      );

    } catch (e) {
      throw Exception('Gagal mengirim pesan: $e');
    }
  }

  // Mark messages as read
  Future<void> markAsRead(String roomId, String userId) async {
    // Implementasi logic update is_read = true untuk pesan yang bukan dari userId ini
    // Ini bisa berat jika banyak pesan, biasanya dilakukan batching atau logic di sisi server (Appwrite Functions)
    // Untuk Client-side implementation sederhana:
    /* 
    final unreadMessages = await _client.databases.listDocuments(
      ... Query.equal('room_id', roomId), Query.equal('is_read', false), Query.notEqual('sender_id', userId)
    );
    for (var msg in unreadMessages.documents) {
       updateDocument(msg.$id, {'is_read': true});
    }
    */
  }

  // ================= REALTIME =================
  
  // Subscribe ke Pesan Baru di Room tertentu
  RealtimeSubscription subscribeToRoom(String roomId) {
    return _client.realtime.subscribe([
      'databases.${AppConstants.databaseId}.collections.${AppConstants.chatMessagesCollectionId}.documents'
    ]);
  }
}