import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase/supabase_config.dart';
import '../models/notification.dart';
import 'opportunity_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final Uuid _uuid = const Uuid();
  final OpportunityService _opportunityService = OpportunityService();

  /// Send a new notification to a user
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? opportunityId,
  }) async {
    try {
      final notification = AppNotification(
        id: _uuid.v4(),
        userId: userId,
        title: title,
        message: message,
        type: type,
        timestamp: DateTime.now(),
        opportunityId: opportunityId,
      );

      await SupabaseService.insert('notifications', notification.toJson());
    } catch (e) {
      throw Exception('Failed to send notification: $e');
    }
  }

  /// Get all notifications for a specific user
  Future<List<AppNotification>> getUserNotifications(String userId) async {
    try {
      final data = await SupabaseService.select(
        'notifications',
        filters: {'user_id': userId},
        orderBy: 'timestamp',
        ascending: false,
      );
      
      return data.map((notification) => AppNotification.fromJson(notification)).toList();
    } catch (e) {
      throw Exception('Failed to get user notifications: $e');
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await SupabaseService.update(
        'notifications',
        {'is_read': true},
        filters: {'id': notificationId},
      );
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      // Using raw SQL for bulk update would be more efficient, but using the generic service for simplicity
      final notifications = await SupabaseService.select(
        'notifications',
        filters: {
          'user_id': userId,
          'is_read': false,
        },
      );

      for (final notification in notifications) {
        await markAsRead(notification['id']);
      }
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await SupabaseService.delete(
        'notifications',
        filters: {'id': notificationId},
      );
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  /// Get unread count for a user
  Future<int> getUnreadCount(String userId) async {
    try {
      final notifications = await SupabaseService.select(
        'notifications',
        filters: {
          'user_id': userId,
          'is_read': false,
        },
      );
      
      return notifications.length;
    } catch (e) {
      throw Exception('Failed to get unread count: $e');
    }
  }

  /// Listen for application status changes via Supabase realtime and create
  /// user notifications when status becomes accepted/rejected.
  RealtimeChannel subscribeToApplicationStatusChanges(String userId, {void Function(AppNotification)? onCreated}) {
    final channel = SupabaseConfig.client
        .channel('public:applications:user:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'applications',
          callback: (payload) async {
            final newRec = payload.newRecord;
            final oldRec = payload.oldRecord;
            if (newRec.isEmpty || newRec['user_id'] != userId) return;
            final newStatus = (newRec['status'] ?? '').toString().toLowerCase();
            final oldStatus = (oldRec['status'] ?? '').toString().toLowerCase();
            if (newStatus == oldStatus) return;
            if (newStatus == 'accepted' || newStatus == 'rejected') {
              final oppId = newRec['opportunity_id']?.toString();
              String oppTitle = '';
              if (oppId != null) {
                try {
                  final opp = await _opportunityService.getOpportunityById(oppId);
                  oppTitle = opp?.title ?? '';
                } catch (_) {}
              }
              final title = newStatus == 'accepted' ? 'Application Approved' : 'Application Rejected';
              final message = newStatus == 'accepted'
                  ? (oppTitle.isNotEmpty
                      ? 'You have been approved for $oppTitle.'
                      : 'You have been approved for an opportunity.')
                  : (oppTitle.isNotEmpty
                      ? 'Your application for $oppTitle was rejected.'
                      : 'Your application was rejected.');
              final created = AppNotification(
                id: _uuid.v4(),
                userId: userId,
                title: title,
                message: message,
                type: 'application_update',
                timestamp: DateTime.now(),
                opportunityId: oppId,
              );
              try {
                await SupabaseService.insert('notifications', created.toJson());
                if (onCreated != null) onCreated(created);
              } catch (_) {}
            }
          },
        )
        .subscribe();
    return channel;
  }
}