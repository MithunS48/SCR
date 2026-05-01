import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class ChatMessage {
  final int id;
  final int senderId;
  final String senderDisplayName;
  final String senderRole;
  final String content;
  final String sentAt;
  final bool deleted;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderDisplayName,
    required this.senderRole,
    required this.content,
    required this.sentAt,
    required this.deleted,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'],
        senderId: j['senderId'],
        senderDisplayName: j['senderDisplayName'] ?? 'Unknown',
        senderRole: j['senderRole'] ?? 'USER',
        content: j['content'],
        sentAt: j['sentAt'] ?? '',
        deleted: j['deleted'] ?? false,
      );

  bool get isAdmin => senderRole == 'ADMIN';
}

/// Community chat screen — all users and admins can communicate.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiClient _api = ApiClient();
  final _messageCtrl   = TextEditingController();
  final _scrollCtrl    = ScrollController();
  List<ChatMessage> _messages = [];
  bool _loading  = false;
  bool _sending  = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    // Poll for new messages every 5 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _pollMessages());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _loading = true);
    try {
      final res = await _api.dio.get(ApiConstants.chat,
          queryParameters: {'page': 0, 'size': 100});
      final content = res.data['data']['content'] as List;
      setState(() {
        _messages = content.map((e) => ChatMessage.fromJson(e)).toList();
      });
      _scrollToBottom();
    } catch (_) {
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pollMessages() async {
    try {
      final res = await _api.dio.get(ApiConstants.chatLatest,
          queryParameters: {'size': 20});
      final content = res.data['data']['content'] as List;
      final latest = content.map((e) => ChatMessage.fromJson(e)).toList();

      // Add only new messages
      final existingIds = _messages.map((m) => m.id).toSet();
      final newMessages = latest.where((m) => !existingIds.contains(m.id)).toList();

      if (newMessages.isNotEmpty) {
        setState(() {
          _messages.addAll(newMessages.reversed);
        });
        _scrollToBottom();
      }
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    try {
      final res = await _api.dio.post(ApiConstants.chat,
          data: {'content': text});
      final newMsg = ChatMessage.fromJson(res.data['data']);
      setState(() {
        _messages.add(newMsg);
        _messageCtrl.clear();
      });
      _scrollToBottom();
    } on DioException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.response?.data?['message'] ?? 'Failed to send message'),
        backgroundColor: AppTheme.error,
      ));
    } finally {
      setState(() => _sending = false);
    }
  }

  Future<void> _deleteMessage(int id) async {
    try {
      await _api.dio.delete('${ApiConstants.chat}/$id');
      setState(() {
        final idx = _messages.indexWhere((m) => m.id == id);
        if (idx != -1) {
          _messages[idx] = ChatMessage(
            id: _messages[idx].id,
            senderId: _messages[idx].senderId,
            senderDisplayName: _messages[idx].senderDisplayName,
            senderRole: _messages[idx].senderRole,
            content: '[Message deleted]',
            sentAt: _messages[idx].sentAt,
            deleted: true,
          );
        }
      });
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
      return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().user;
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.chat_bubble_outline, size: 20),
            SizedBox(width: 8),
            Text('Community Chat'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Online indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: AppTheme.primary.withOpacity(0.08),
            child: Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text('Community Chat — Open to all members',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),

          // Messages list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 64,
                                color: AppTheme.textSecondary),
                            SizedBox(height: 12),
                            Text('No messages yet. Start the conversation!',
                                style: TextStyle(color: AppTheme.textSecondary)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.all(12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg.senderId == currentUser?.id;
                          return _MessageBubble(
                            message: msg,
                            isMe: isMe,
                            isAdmin: isAdmin,
                            onDelete: isAdmin && !msg.deleted
                                ? () => _deleteMessage(msg.id)
                                : null,
                            formatTime: _formatTime,
                          );
                        },
                      ),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.06),
                    blurRadius: 8, offset: const Offset(0, -2)),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageCtrl,
                    maxLines: null,
                    maxLength: 1000,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      counterText: '',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: _sending
                      ? const SizedBox(
                          width: 44, height: 44,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : FloatingActionButton.small(
                          onPressed: _sendMessage,
                          backgroundColor: AppTheme.primary,
                          elevation: 0,
                          child: const Icon(Icons.send, color: Colors.white, size: 18),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool isAdmin;
  final VoidCallback? onDelete;
  final String Function(String) formatTime;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.isAdmin,
    required this.formatTime,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            // Avatar
            CircleAvatar(
              radius: 16,
              backgroundColor: message.isAdmin
                  ? Colors.deepPurple.withOpacity(0.2)
                  : AppTheme.primary.withOpacity(0.2),
              child: Text(
                message.senderDisplayName[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: message.isAdmin ? Colors.deepPurple : AppTheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],

          // Bubble
          Flexible(
            child: GestureDetector(
              onLongPress: onDelete != null
                  ? () => _showDeleteDialog(context)
                  : null,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.65,
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: message.deleted
                      ? Colors.grey[200]
                      : isMe
                          ? AppTheme.primary
                          : message.isAdmin
                              ? Colors.deepPurple[50]
                              : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: message.isAdmin && !isMe
                      ? Border.all(color: Colors.deepPurple.withOpacity(0.2))
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    // Sender name + role badge
                    if (!isMe)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            message.senderDisplayName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: message.isAdmin
                                  ? Colors.deepPurple
                                  : AppTheme.primary,
                            ),
                          ),
                          if (message.isAdmin) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('ADMIN',
                                  style: TextStyle(color: Colors.white,
                                      fontSize: 8, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                    if (!isMe) const SizedBox(height: 3),

                    // Message content
                    Text(
                      message.content,
                      style: TextStyle(
                        color: message.deleted
                            ? Colors.grey
                            : isMe
                                ? Colors.white
                                : AppTheme.textPrimary,
                        fontSize: 14,
                        fontStyle: message.deleted
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
                    const SizedBox(height: 3),

                    // Timestamp
                    Text(
                      formatTime(message.sentAt),
                      style: TextStyle(
                        fontSize: 10,
                        color: isMe
                            ? Colors.white70
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (isMe) const SizedBox(width: 6),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Remove this message from the chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
