import 'package:flutter/material.dart';
import 'package:mavenlink/models/chat_message.dart';
import 'package:mavenlink/models/user.dart' as app_models;
import 'package:mavenlink/services/chat_service.dart';
import 'package:mavenlink/services/user_service.dart';
import 'package:mavenlink/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatScreen extends StatefulWidget {
  final String? userId; // For admin to chat with specific user
  
  const ChatScreen({super.key, this.userId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  app_models.User? _currentUser;
  app_models.User? _chatPartner;
  List<ChatMessage> _messages = [];
  List<UserChatSummary> _userChatSummaries = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _showUserList = true;
  RealtimeChannel? _chatChannel;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _unsubscribeChat();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await UserService.getCurrentUser();
      if (user != null) {
        setState(() {
          _currentUser = user;
        });

        if (user.isAdmin) {
          // Admin view: show user list or specific chat
          if (widget.userId != null) {
            await _loadChatWithUser(widget.userId!);
          } else {
            await _loadUserChatSummaries();
          }
        } else {
          // Regular user: chat with admin
          await _loadChatWithAdmin();
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading chat: $e')),
        );
      }
    }
  }

  Future<void> _loadUserChatSummaries() async {
    if (_currentUser == null) return;
    try {
      final userIds = await _chatService.getUsersWithMessages();
      final List<UserChatSummary> summaries = [];
      for (final uid in userIds) {
        // Skip admin ids if any; conversations are keyed by end-user id
        final user = await UserService.getProfile(uid);
        if (user == null) continue;
        final messages = await _chatService.getMessagesForUser(uid);
        if (messages.isEmpty) continue;
        final unread = await _chatService.getUnreadCount(uid, _currentUser!.id);
        final last = messages.last;
        summaries.add(
          UserChatSummary(
            userId: uid,
            userName: user.name.isNotEmpty ? user.name : user.email,
            lastMessage: last.message,
            lastMessageTime: last.timestamp,
            unreadCount: unread,
          ),
        );
      }
      // Sort by last message time desc
      summaries.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      setState(() {
        _userChatSummaries = summaries;
        _showUserList = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _userChatSummaries = [];
        _showUserList = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadChatWithUser(String userId) async {
    final chatPartner = await UserService.getProfile(userId);
    final messages = await _chatService.getMessagesForUser(userId);
    
    // Mark incoming messages as read
    if (_currentUser != null) {
      await _chatService.markAsRead(userId, _currentUser!.id);
    }
    
    setState(() {
      _chatPartner = chatPartner;
      _messages = messages;
      _showUserList = false;
      _isLoading = false;
    });
    
    _subscribeToChat(userId);
    _scrollToBottom();
  }

  Future<void> _loadChatWithAdmin() async {
    // For a regular user, the conversation key is their own user id
    if (_currentUser == null) return;
    final conversationUserId = _currentUser!.id;
    final messages = await _chatService.getMessagesForUser(conversationUserId);
    
    setState(() {
      _messages = messages;
      _showUserList = false;
      _isLoading = false;
    });
    
    // Mark as read and subscribe
    await _chatService.markAsRead(conversationUserId, _currentUser!.id);
    _subscribeToChat(conversationUserId);
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _isSending = true;
    });

    try {
      // Conversation key is always the end user's id
      final String targetUserId = _currentUser!.isAdmin
          ? _chatPartner!.id
          : _currentUser!.id;

      await _chatService.sendMessage(
        userId: targetUserId,
        senderId: _currentUser!.id,
        message: messageText,
      );
      
      // Optimistically append message; realtime will also deliver it
      setState(() {
        _messages = List.of(_messages)
          ..add(ChatMessage(
            id: 'local',
            userId: targetUserId,
            senderId: _currentUser!.id,
            message: messageText,
            timestamp: DateTime.now(),
            isRead: false,
          ));
      });
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _subscribeToChat(String conversationUserId) {
    _unsubscribeChat();
    _chatChannel = _chatService.subscribeToConversation(
      conversationUserId: conversationUserId,
      onInsert: (msg) {
        // Avoid duplicates if we already appended optimistically
        final exists = _messages.any((m) => m.id == msg.id);
        if (!exists) {
          setState(() => _messages = List.of(_messages)..add(msg));
          _scrollToBottom();
        }
      },
    );
  }

  void _unsubscribeChat() {
    if (_chatChannel != null) {
      Supabase.instance.client.removeChannel(_chatChannel!);
      _chatChannel = null;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: const Text('Chat'),
          backgroundColor: colorScheme.surface,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser!.isAdmin && _showUserList) {
      return _buildAdminUserList();
    }

    return _buildChatInterface();
  }

  Widget _buildAdminUserList() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'User Chats',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: _userChatSummaries.isEmpty
          ? _buildEmptyUserList()
          : RefreshIndicator(
              onRefresh: _loadUserChatSummaries,
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _userChatSummaries.length,
                itemBuilder: (context, index) {
                  final summary = _userChatSummaries[index];
                  return _buildUserChatCard(summary);
                },
              ),
            ),
    );
  }

  Widget _buildEmptyUserList() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_outlined,
            size: 80,
            color: colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Users will appear here when they send messages',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUserChatCard(UserChatSummary summary) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _loadChatWithUser(summary.userId),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: colorScheme.primary,
                    child: Text(
                      summary.userName.isNotEmpty ? summary.userName[0].toUpperCase() : 'U',
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  if (summary.unreadCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: colorScheme.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          '${summary.unreadCount}',
                          style: TextStyle(
                            color: colorScheme.onError,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.userName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      summary.lastMessage,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatMessageTime(summary.lastMessageTime),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: colorScheme.onSurface.withOpacity(0.4),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatInterface() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentUser!.isAdmin 
                  ? _chatPartner?.name ?? 'User'
                  : 'Admin Support',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_currentUser!.isAdmin && _chatPartner != null)
              Text(
                _chatPartner!.email,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
          ],
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: _currentUser!.isAdmin 
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
                onPressed: () => setState(() {
                  _showUserList = true;
                  _chatPartner = null;
                  _messages = [];
                }),
              )
            : null,
        automaticallyImplyLeading: !_currentUser!.isAdmin,
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyChat()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
          ),
          
          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyChat() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation by sending a message',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isFromCurrentUser = message.senderId == _currentUser!.id;
    final isFromAdmin = !_currentUser!.isAdmin && !isFromCurrentUser;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isFromCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isFromCurrentUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: isFromAdmin ? colorScheme.secondary : colorScheme.tertiary,
              child: Text(
                isFromAdmin ? 'A' : (_chatPartner?.name.isNotEmpty == true ? _chatPartner!.name[0].toUpperCase() : 'U'),
                style: TextStyle(
                  color: colorScheme.onSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isFromCurrentUser 
                    ? colorScheme.primary 
                    : colorScheme.surfaceVariant.withOpacity(0.7),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isFromCurrentUser ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: isFromCurrentUser ? const Radius.circular(4) : const Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isFromCurrentUser 
                          ? colorScheme.onPrimary 
                          : colorScheme.onSurface,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatMessageTime(message.timestamp),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isFromCurrentUser 
                          ? colorScheme.onPrimary.withOpacity(0.7)
                          : colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isFromCurrentUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primary,
              child: Text(
                _currentUser!.name.isNotEmpty ? _currentUser!.name[0].toUpperCase() : 'U',
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  filled: true,
                  fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _isSending ? null : _sendMessage,
                icon: _isSending
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : Icon(
                        Icons.send,
                        color: colorScheme.onPrimary,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserChatSummary {
  final String userId;
  final String userName;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;

  UserChatSummary({
    required this.userId,
    required this.userName,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
  });
}