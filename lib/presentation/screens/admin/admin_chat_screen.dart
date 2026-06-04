import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/chat_provider.dart';
import '../../theme/app_colors.dart';

class AdminChatScreen extends StatefulWidget {
  final String roomId;
  final String clientName;

  const AdminChatScreen({
    super.key,
    required this.roomId,
    required this.clientName,
  });

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      // Load messages
      chatProvider.loadMessages(widget.roomId);
      
      // Tandai sudah dibaca (Reset Unread Count)
      chatProvider.markRoomAsRead(widget.roomId);
    });
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    final adminId = user?.id ?? 'admin'; 
    final adminName = user?.nama ?? 'Admin';

    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      await chatProvider.sendMessage(
        senderId: adminId,
        senderName: adminName,
        receiverId: widget.roomId, // Penanda receiver pelanggan
        text: _messageController.text,
        isAdmin: true,
      );
      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal membalas: $e"),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  

    @override

    Widget build(BuildContext context) {

      final chatProvider = Provider.of<ChatProvider>(context);

      final user = Provider.of<AuthProvider>(context).currentUser;

      final myId = user?.id ?? 'admin';

  

      // Balik urutan pesan agar terbaru di bawah

      final displayMessages = chatProvider.messages.reversed.toList();

  

      return Scaffold(

        backgroundColor: AppColors.backgroundLight,

        appBar: AppBar(

          backgroundColor: AppColors.primaryDark,

          foregroundColor: Colors.white,

          title: Text(widget.clientName),

        ),

        body: Column(

          children: [

            Expanded(

              child: chatProvider.isLoading && chatProvider.messages.isEmpty

                  ? const Center(child: CircularProgressIndicator())

                  : ListView.builder(

                      reverse: true, // Pesan baru di bawah

                      controller: _scrollController,

                      padding: const EdgeInsets.all(16),

                      itemCount: displayMessages.length,

                      itemBuilder: (context, index) {

                        final message = displayMessages[index];

                        final isMe = message['id_sender'] == myId;

                        return _buildMessageBubble(message, isMe);

                      },

                    ),

            ),

            

            // Input Area

            Container(

              padding: const EdgeInsets.all(16),

              color: Colors.white,

              child: Row(

                children: [

                  IconButton(

                    onPressed: () {}, // Image picker todo

                    icon: const Icon(Icons.attach_file, color: AppColors.textSecondary),

                  ),

                  Expanded(

                    child: TextField(

                      controller: _messageController,

                      decoration: InputDecoration(

                        hintText: "Balas pesan...",

                        border: OutlineInputBorder(

                          borderRadius: BorderRadius.circular(24),

                          borderSide: BorderSide.none,

                        ),

                        filled: true,

                        fillColor: AppColors.backgroundLight,

                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),

                      ),

                      onSubmitted: (_) => _sendMessage(),

                    ),

                  ),

                  const SizedBox(width: 8),

                  CircleAvatar(

                    backgroundColor: AppColors.cyan,

                    child: IconButton(

                      onPressed: _sendMessage,

                      icon: const Icon(Icons.send, color: Colors.white, size: 20),

                    ),

                  ),

                ],

              ),

            ),

          ],

        ),

      );

    }

  

    Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe) {

      return Align(

        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,

        child: Container(

          margin: const EdgeInsets.only(bottom: 12),

          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

          constraints: BoxConstraints(

            maxWidth: MediaQuery.of(context).size.width * 0.75,

          ),

          decoration: BoxDecoration(

            color: isMe ? AppColors.cyan : Colors.white, // Admin warna Cyan

            borderRadius: BorderRadius.only(

              topLeft: const Radius.circular(16),

              topRight: const Radius.circular(16),

              bottomLeft: Radius.circular(isMe ? 16 : 0),

              bottomRight: Radius.circular(isMe ? 0 : 16),

            ),

            boxShadow: [

              BoxShadow(

                color: Colors.black.withOpacity(0.05),

                blurRadius: 4,

                offset: const Offset(0, 2),

              ),

            ],

          ),

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Text(

                message['message'] ?? '',

                style: TextStyle(

                  color: isMe ? Colors.white : AppColors.textPrimary,

                  fontSize: 15,

                ),

              ),

              const SizedBox(height: 4),

              Text(

                DateFormat('HH:mm').format(DateTime.parse(message['timestamp'])),

                style: TextStyle(

                  color: isMe ? Colors.white70 : AppColors.textSecondary,

                  fontSize: 10,

                ),

              ),

            ],

          ),

        ),

      );

    }
}