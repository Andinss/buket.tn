import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat_message.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_service.dart';

class BuyerChatPage extends StatefulWidget {
  final String buyerId;
  final String buyerName;

  const BuyerChatPage({
    super.key,
    required this.buyerId,
    required this.buyerName,
  });

  @override
  State<BuyerChatPage> createState() => _BuyerChatPageState();
}

class _BuyerChatPageState extends State<BuyerChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseService _service = FirebaseService();

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
  }

  Future<void> _markMessagesAsRead() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user != null) {
      try {
        final messagesSnapshot = await _service.db
            .collection('chats')
            .doc(widget.buyerId)
            .collection('messages')
            .where('senderId', isEqualTo: widget.buyerId)
            .where('isRead', isEqualTo: false)
            .get();
        
        final batch = _service.db.batch();
        for (var doc in messagesSnapshot.docs) {
          batch.update(doc.reference, {'isRead': true});
        }
        await batch.commit();
      } catch (e) {
        debugPrint('Error marking messages as read: $e');
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user == null) return;

    try {
      final message = ChatMessage(
        id: '',
        orderId: '', // Tidak perlu order ID karena chat per buyer
        senderId: auth.user!.uid,
        senderName: auth.user!.displayName ?? 'Seller',
        message: _messageController.text.trim(),
        timestamp: DateTime.now(),
        isRead: false,
      );

      // Save to buyer's chat room
      await _service.db
          .collection('chats')
          .doc(widget.buyerId)
          .collection('messages')
          .add(message.toMap());

      // Update last message metadata
      await _service.db.collection('chats').doc(widget.buyerId).set({
        'buyerId': widget.buyerId,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessage': message.message,
        'lastSenderId': message.senderId,
      }, SetOptions(merge: true));

      _messageController.clear();

      // Scroll to bottom
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final currentUserId = auth.user?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3142)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B9D), Color(0xFFFF8FAB)],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  widget.buyerName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.buyerName,
                    style: const TextStyle(
                      color: Color(0xFF2D3142),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  FutureBuilder<int>(
                    future: _getOrdersCount(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data! > 0) {
                        return Text(
                          '${snapshot.data} pesanan',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _service.db
                  .collection('chats')
                  .doc(widget.buyerId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots()
                  .map((snapshot) {
                    return snapshot.docs.map((doc) {
                      try {
                        return ChatMessage.fromDoc(doc);
                      } catch (e) {
                        debugPrint('Error parsing message: $e');
                        return null;
                      }
                    }).whereType<ChatMessage>().toList();
                  }),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF6B9D)),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada pesan',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Mulai percakapan dengan ${widget.buyerName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId;

                    // Show order context if message has orderId
                    Widget messageWidget = _buildMessageBubble(message, isMe);
                    
                    if (message.orderId.isNotEmpty && 
                        (index == 0 || messages[index - 1].orderId != message.orderId)) {
                      messageWidget = Column(
                        children: [
                          _buildOrderContext(message.orderId),
                          const SizedBox(height: 8),
                          messageWidget,
                        ],
                      );
                    } else {
                      messageWidget = messageWidget;
                    }

                    return messageWidget;
                  },
                );
              },
            ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Tulis pesan...',
                          hintStyle: TextStyle(fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF6B9D),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderContext(String orderId) {
    if (orderId.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<DocumentSnapshot>(
      future: _service.db.collection('orders').doc(orderId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        // ignore: unused_local_variable
        final orderData = snapshot.data!.data() as Map<String, dynamic>;
        final orderNumber = orderId.substring(0, 8).toUpperCase();

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shopping_bag, size: 16, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'Order #$orderNumber',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFFF6B9D),
              child: Text(
                message.senderName.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 4),
                    child: Text(
                      message.senderName,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xFFFF6B9D) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.message,
                    style: TextStyle(
                      fontSize: 14,
                      color: isMe ? Colors.white : const Color(0xFF2D3142),
                      height: 1.4,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFFF6B9D),
              child: Text(
                message.senderName.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${time.day}/${time.month}/${time.year} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit lalu';
    } else {
      return 'Baru saja';
    }
  }

  Future<int> _getOrdersCount() async {
    try {
      final snapshot = await _service.db
          .collection('orders')
          .where('buyerId', isEqualTo: widget.buyerId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }
}