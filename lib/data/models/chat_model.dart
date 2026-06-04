import 'package:appwrite/models.dart';

enum MessageType { text, image, system, reservation, payment }

class ChatMessage {
  final String id;
  final String roomId;
  final String senderId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final String? attachmentUrl;

  ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.attachmentUrl,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, {String? id}) {
    return ChatMessage(
      id: id ?? json['\$id'] ?? '',
      roomId: json['room_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      content: json['content'] ?? '',
      type: _parseType(json['type']),
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      isRead: json['is_read'] ?? false,
      attachmentUrl: json['attachment_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'room_id': roomId,
      'sender_id': senderId,
      'content': content,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      'attachment_url': attachmentUrl,
    };
  }

  static MessageType _parseType(String? type) {
    switch (type) {
      case 'image': return MessageType.image;
      case 'system': return MessageType.system;
      case 'reservation': return MessageType.reservation;
      case 'payment': return MessageType.payment;
      default: return MessageType.text;
    }
  }
}

class ChatRoom {
  final String id;
  final List<String> participants; // [clientId, adminId]
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final String clientName; // Helper for display
  final String? clientAvatar; // Helper for display

  ChatRoom({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.clientName = 'Pelanggan',
    this.clientAvatar,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json, {String? id}) {
    return ChatRoom(
      id: id ?? json['\$id'] ?? '',
      participants: List<String>.from(json['participants'] ?? []),
      lastMessage: json['last_message'] ?? '',
      lastMessageTime: DateTime.parse(json['last_message_time'] ?? DateTime.now().toIso8601String()),
      unreadCount: json['unread_count'] ?? 0,
      clientName: json['client_name'] ?? 'Pelanggan',
    );
  }
  
  // Method untuk update local state unread count
  ChatRoom copyWith({int? unreadCount, String? lastMessage, DateTime? lastMessageTime}) {
    return ChatRoom(
      id: id,
      participants: participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      clientName: clientName,
      clientAvatar: clientAvatar,
    );
  }
}