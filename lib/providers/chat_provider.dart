import 'dart:async';
import 'package:flutter/material.dart';
import '../data/services/database_service.dart';

class ChatProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  // State
  List<Map<String, dynamic>> _adminRooms = []; // Daftar room untuk admin
  List<Map<String, dynamic>> _messages = [];   // Pesan aktif di layar chat
  String? _activeRoomId;
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get adminRooms => _adminRooms;
  List<Map<String, dynamic>> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get activeRoomId => _activeRoomId;
  String? get error => _error;
  
  // Hitung total pesan belum terbaca untuk badge notifikasi admin
  int get totalUnreadCount {
    int total = 0;
    for (var room in _adminRooms) {
      // Ambil unread_count, pastikan tipe datanya aman (int)
      final count = room['unread_count'];
      if (count is int) {
        total += count;
      }
    }
    return total;
  }

  // ================= CLIENT: INIT CHAT =================
  Future<void> initClientChat(String userId, String userName) async {
    _setLoading(true);
    _error = null;
    try {
      final roomId = await _dbService.getOrCreateChatRoom(userId, userName);
      _activeRoomId = roomId;
      await loadMessages(roomId);
      _startPolling(roomId);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error init chat: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ================= ADMIN: LOAD ROOMS =================
  Future<void> loadAdminRooms() async {
    _setLoading(true);
    _error = null;
    try {
      _adminRooms = await _dbService.getAllChatRooms();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading rooms: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ================= GENERAL: LOAD MESSAGES =================
  Future<void> loadMessages(String roomId) async {
    _activeRoomId = roomId;
    try {
      _messages = await _dbService.getChatMessages(roomId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading messages: $e');
    }
  }

  // ================= GENERAL: SEND MESSAGE =================
  Future<void> sendMessage({
    required String senderId,
    required String senderName,
    required String receiverId,
    required String text,
    required bool isAdmin,
  }) async {
    if (_activeRoomId == null) return;
    _error = null;

    try {
      // Optimistic Update
      final tempMessage = {
        'id_chatroom': _activeRoomId,
        'id_sender': senderId,
        'sender_name': senderName,
        'id_receiver': receiverId,
        'message': text,
        'timestamp': DateTime.now().toIso8601String(),
        'isread': false,
        'type': 'text',
        'pending': true,
      };
      
      _messages.add(tempMessage);
      notifyListeners();

      await _dbService.sendMessage(
        roomId: _activeRoomId!,
        senderId: senderId,
        senderName: senderName,
        receiverId: receiverId,
        text: text,
        isAdmin: isAdmin,
      );
      
      await loadMessages(_activeRoomId!);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error sending message: $e');
      _messages.removeLast();
      notifyListeners();
      rethrow;
    }
  }

  // ================= GENERAL: MARK AS READ =================
  Future<void> markRoomAsRead(String roomId) async {
    // 1. Optimistic Update (Lokal)
    final index = _adminRooms.indexWhere((r) => r['\$id'] == roomId);
    if (index != -1) {
      _adminRooms[index]['unread_count'] = 0;
      notifyListeners();
    }

    // 2. Update Database
    try {
      await _dbService.markChatAsRead(roomId);
    } catch (e) {
      debugPrint("Error marking room as read: $e");
    }
  }

  // ================= POLLING SYSTEM =================
  Timer? _pollingTimer;

  void _startPolling(String roomId) {
    _stopPolling();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      loadMessages(roomId);
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}