import 'package:flutter/material.dart';

import '../services/firebase_service.dart';
import '../models/chat_message.dart';
import '../pages/buyer_chat_page.dart';

class SellerChatListPage extends StatelessWidget {
  const SellerChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FirebaseService();

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Chat Pembeli',
          style: TextStyle(
            color: Color(0xFF2D3142),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: service.getSellerChatConversations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF6B9D)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 80, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          final conversations = snapshot.data ?? [];

          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(40),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFE8F0),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      size: 80,
                      color: Color(0xFFFF6B9D),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Belum Ada Chat',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Chat dengan pembeli akan muncul di sini',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conv = conversations[index];
              final buyerId = conv['buyerId'] as String;
              final buyerName = conv['buyerName'] as String;
              final ordersCount = conv['ordersCount'] as int;
              final lastMessage = conv['lastMessage'] as ChatMessage?;
              final unreadCount = conv['unreadCount'] as int;

              return _buildChatItem(
                context,
                buyerId,
                buyerName,
                ordersCount,
                lastMessage,
                unreadCount,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildChatItem(
    BuildContext context,
    String buyerId,
    String buyerName,
    int ordersCount,
    ChatMessage? lastMessage,
    int unreadCount,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BuyerChatPage(
              buyerId: buyerId,
              buyerName: buyerName,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B9D), Color(0xFFFF8FAB)],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  buyerName.isNotEmpty 
                      ? buyerName.substring(0, 1).toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          buyerName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3142),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (lastMessage != null)
                        Text(
                          _formatTime(lastMessage.timestamp),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  Text(
                    '$ordersCount pesanan',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  if (lastMessage != null)
                    Text(
                      lastMessage.message,
                      style: TextStyle(
                        fontSize: 13,
                        color: unreadCount > 0
                            ? const Color(0xFF2D3142)
                            : Colors.grey.shade600,
                        fontWeight: unreadCount > 0
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Text(
                      'Belum ada pesan',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            
            // Unread badge
            if (unreadCount > 0)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF6B9D),
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 24,
                  minHeight: 24,
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : '$unreadCount',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Kemarin';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} hari';
      } else {
        return '${time.day}/${time.month}';
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours}j';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Baru';
    }
  }
}