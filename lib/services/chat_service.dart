import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase/supabase_config.dart';
import '../models/chat_message.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final Uuid _uuid = const Uuid();

  /// Subscribe to realtime chat messages for a given user conversation.
  ///
  /// Conversation key is the end-user's id (not admin id). Both sides write
  /// messages with user_id = that end-user id.
  RealtimeChannel subscribeToConversation({
    required String conversationUserId,
    required void Function(ChatMessage message) onInsert,
  }) {
    final channel = SupabaseConfig.client
        .channel('public:chat_messages:user:$conversationUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          callback: (payload) {
            final record = payload.newRecord;
            if (record.isNotEmpty && record['user_id'] == conversationUserId) {
              try {
                final msg = ChatMessage.fromJson(record);
                onInsert(msg);
              } catch (_) {}
            }
          },
        )
        .subscribe();

    return channel;
  }

  /// Send a message
  Future<ChatMessage> sendMessage({
    required String userId,
    required String senderId,
    required String message,
  }) async {
    try {
      final chatMessage = ChatMessage(
        id: _uuid.v4(),
        userId: userId,
        senderId: senderId,
        message: message,
        timestamp: DateTime.now(),
      );

      await SupabaseService.insert('chat_messages', chatMessage.toJson());

      return chatMessage;
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Get messages for a specific user (conversation between user and admin)
  Future<List<ChatMessage>> getMessagesForUser(String userId) async {
    try {
      final data = await SupabaseService.select(
        'chat_messages',
        filters: {'user_id': userId},
        orderBy: 'timestamp',
        ascending: true,
      );
      
      return data.map((message) => ChatMessage.fromJson(message)).toList();
    } catch (e) {
      throw Exception('Failed to get messages for user: $e');
    }
  }

  /// Get all user chats (for admin to see all user conversations)
  Future<Map<String, List<ChatMessage>>> getUserChats() async {
    try {
      final data = await SupabaseService.select(
        'chat_messages',
        orderBy: 'timestamp',
        ascending: true,
      );
      
      final chatMessages = data.map((message) => ChatMessage.fromJson(message)).toList();

      // Group messages by userId
      final Map<String, List<ChatMessage>> userChats = {};
      for (final message in chatMessages) {
        if (!userChats.containsKey(message.userId)) {
          userChats[message.userId] = [];
        }
        userChats[message.userId]!.add(message);
      }

      return userChats;
    } catch (e) {
      throw Exception('Failed to get user chats: $e');
    }
  }

  /// Get users with recent messages (for admin chat list)
  Future<List<String>> getUsersWithMessages() async {
    try {
      final data = await SupabaseService.select('chat_messages');
      final userIds = data
          .map((message) => message['user_id'] as String)
          .toSet()
          .toList();
      
      return userIds;
    } catch (e) {
      throw Exception('Failed to get users with messages: $e');
    }
  }

  /// Mark messages as read for a specific user
  Future<void> markAsRead(String userId, String readerId) async {
    try {
      // Get unread messages for the user that were not sent by the reader
      final unreadMessages = await SupabaseService.select(
        'chat_messages',
        filters: {
          'user_id': userId,
          'is_read': false,
        },
      );

      // Filter out messages sent by the reader and mark others as read
      for (final message in unreadMessages) {
        if (message['sender_id'] != readerId) {
          await SupabaseService.update(
            'chat_messages',
            {'is_read': true},
            filters: {'id': message['id']},
          );
        }
      }
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  /// Get unread message count for a specific user
  Future<int> getUnreadCount(String userId, String readerId) async {
    try {
      final messages = await getMessagesForUser(userId);
      return messages
          .where((message) => !message.isRead && message.senderId != readerId)
          .length;
    } catch (e) {
      throw Exception('Failed to get unread count: $e');
    }
  }

  /// Get latest message for each user (for admin chat overview)
  Future<Map<String, ChatMessage>> getLatestMessagesPerUser() async {
    try {
      final userChats = await getUserChats();
      final Map<String, ChatMessage> latestMessages = {};
      
      userChats.forEach((userId, messages) {
        if (messages.isNotEmpty) {
          latestMessages[userId] = messages.last;
        }
      });
      
      return latestMessages;
    } catch (e) {
      throw Exception('Failed to get latest messages per user: $e');
    }
  }
}