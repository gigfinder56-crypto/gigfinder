import 'package:uuid/uuid.dart';
import '../supabase/supabase_config.dart';
import 'notification_service.dart';
import 'opportunity_service.dart';
import '../models/application.dart';

class ApplicationService {
  static final ApplicationService _instance = ApplicationService._internal();
  factory ApplicationService() => _instance;
  ApplicationService._internal();

  final Uuid _uuid = const Uuid();
  final NotificationService _notificationService = NotificationService();
  final OpportunityService _opportunityService = OpportunityService();

  /// Submit a new application
  Future<Application> submitApplication({
    required String userId,
    required String opportunityId,
  }) async {
    try {
      // Check if user has already applied for this opportunity
      final existingApplication = await SupabaseService.selectSingle(
        'applications',
        filters: {
          'user_id': userId,
          'opportunity_id': opportunityId,
        },
      );
      
      if (existingApplication != null) {
        throw Exception('You have already applied for this opportunity');
      }

      final now = DateTime.now();
      final application = Application(
        id: _uuid.v4(),
        userId: userId,
        opportunityId: opportunityId,
        appliedDate: now,
        createdAt: now,
        updatedAt: now,
      );

      await SupabaseService.insert('applications', application.toJson());

      // Send notification to user
      final opportunity = await _opportunityService.getOpportunityById(opportunityId);
      if (opportunity != null) {
        await _notificationService.sendNotification(
          userId: userId,
          title: 'Application Submitted',
          message: 'Your application for ${opportunity.title} has been submitted successfully.',
          type: 'application_update',
          opportunityId: opportunityId,
        );
      }

      return application;
    } catch (e) {
      throw Exception('Failed to submit application: $e');
    }
  }

  /// Get applications for a specific user
  Future<List<Application>> getUserApplications(String userId) async {
    try {
      final data = await SupabaseService.select(
        'applications',
        filters: {'user_id': userId},
        orderBy: 'applied_date',
        ascending: false,
      );
      
      return data.map((application) => Application.fromJson(application)).toList();
    } catch (e) {
      throw Exception('Failed to get user applications: $e');
    }
  }

  /// Get all applications (admin only)
  Future<List<Application>> getAllUserApplications() async {
    try {
      final data = await SupabaseService.select(
        'applications',
        orderBy: 'applied_date',
        ascending: false,
      );
      
      return data.map((application) => Application.fromJson(application)).toList();
    } catch (e) {
      throw Exception('Failed to get all applications: $e');
    }
  }

  /// Update application status (admin only)
  Future<void> updateApplicationStatus(String applicationId, String status, {String? adminNotes}) async {
    try {
      final applicationData = await SupabaseService.selectSingle(
        'applications',
        filters: {'id': applicationId},
      );
      
      if (applicationData == null) {
        throw Exception('Application not found');
      }

      final oldApplication = Application.fromJson(applicationData);
      final updatedData = {
        'status': status,
        'admin_notes': adminNotes ?? oldApplication.adminNotes,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await SupabaseService.update(
        'applications',
        updatedData,
        filters: {'id': applicationId},
      );

      // Send notification if status changed to accepted or rejected
      if (status == 'accepted' || status == 'rejected') {
        final opportunity = await _opportunityService.getOpportunityById(oldApplication.opportunityId);
        final title = status == 'accepted' ? 'Application Accepted' : 'Application Rejected';
        final message = status == 'accepted' 
            ? 'Congratulations! Your application for ${opportunity?.title ?? 'the opportunity'} has been accepted.'
            : 'Your application for ${opportunity?.title ?? 'the opportunity'} has been rejected.';

        await _notificationService.sendNotification(
          userId: oldApplication.userId,
          title: title,
          message: message,
          type: 'application_update',
          opportunityId: oldApplication.opportunityId,
        );
      }
    } catch (e) {
      throw Exception('Failed to update application status: $e');
    }
  }

  /// Get application by ID
  Future<Application?> getApplicationById(String applicationId) async {
    try {
      final applicationData = await SupabaseService.selectSingle(
        'applications',
        filters: {'id': applicationId},
      );
      
      return applicationData != null ? Application.fromJson(applicationData) : null;
    } catch (e) {
      throw Exception('Failed to get application by ID: $e');
    }
  }

  /// Get applications for a specific opportunity
  Future<List<Application>> getApplicationsForOpportunity(String opportunityId) async {
    try {
      final data = await SupabaseService.select(
        'applications',
        filters: {'opportunity_id': opportunityId},
        orderBy: 'applied_date',
        ascending: false,
      );
      
      return data.map((application) => Application.fromJson(application)).toList();
    } catch (e) {
      throw Exception('Failed to get applications for opportunity: $e');
    }
  }
}