import 'package:uuid/uuid.dart';
import '../supabase/supabase_config.dart';
import '../models/experience.dart';

class ExperienceService {
  static final ExperienceService _instance = ExperienceService._internal();
  factory ExperienceService() => _instance;
  ExperienceService._internal();

  final Uuid _uuid = const Uuid();

  /// Create a new experience
  Future<Experience> createExperience({
    required String userId,
    required String userName,
    required String opportunityId,
    required String opportunityTitle,
    required String title,
    required String content,
    required double rating,
  }) async {
    try {
      if (rating < 1.0 || rating > 5.0) {
        throw Exception('Rating must be between 1.0 and 5.0');
      }

      final now = DateTime.now();
      final experience = Experience(
        id: _uuid.v4(),
        userId: userId,
        userName: userName,
        opportunityId: opportunityId,
        opportunityTitle: opportunityTitle,
        title: title,
        content: content,
        rating: rating,
        postedDate: now,
        createdAt: now,
        updatedAt: now,
      );

      await SupabaseService.insert('experiences', experience.toJson());

      return experience;
    } catch (e) {
      throw Exception('Failed to create experience: $e');
    }
  }

  /// Get experiences for a specific opportunity
  Future<List<Experience>> getExperiencesByOpportunity(String opportunityId) async {
    try {
      final data = await SupabaseService.select(
        'experiences',
        filters: {'opportunity_id': opportunityId},
        orderBy: 'posted_date',
        ascending: false,
      );
      
      return data.map((experience) => Experience.fromJson(experience)).toList();
    } catch (e) {
      throw Exception('Failed to get experiences by opportunity: $e');
    }
  }

  /// Get all experiences
  Future<List<Experience>> getAllUserExperiences() async {
    try {
      final data = await SupabaseService.select(
        'experiences',
        orderBy: 'posted_date',
        ascending: false,
      );
      
      return data.map((experience) => Experience.fromJson(experience)).toList();
    } catch (e) {
      throw Exception('Failed to get all experiences: $e');
    }
  }

  /// Get experiences for a specific user
  Future<List<Experience>> getUserExperiences(String userId) async {
    try {
      final data = await SupabaseService.select(
        'experiences',
        filters: {'user_id': userId},
        orderBy: 'posted_date',
        ascending: false,
      );
      
      return data.map((experience) => Experience.fromJson(experience)).toList();
    } catch (e) {
      throw Exception('Failed to get user experiences: $e');
    }
  }

  /// Delete an experience (only by the user who created it or admin)
  Future<void> deleteExperience(String experienceId, {String? userId}) async {
    try {
      // If userId is provided, check if the user owns the experience
      if (userId != null) {
        final experienceData = await SupabaseService.selectSingle(
          'experiences',
          filters: {'id': experienceId},
        );
        
        if (experienceData == null) {
          throw Exception('Experience not found');
        }

        if (experienceData['user_id'] != userId) {
          throw Exception('You can only delete your own experiences');
        }
      }

      await SupabaseService.delete(
        'experiences',
        filters: {'id': experienceId},
      );
    } catch (e) {
      throw Exception('Failed to delete experience: $e');
    }
  }

  /// Get experience by ID
  Future<Experience?> getExperienceById(String experienceId) async {
    try {
      final experienceData = await SupabaseService.selectSingle(
        'experiences',
        filters: {'id': experienceId},
      );
      
      return experienceData != null ? Experience.fromJson(experienceData) : null;
    } catch (e) {
      throw Exception('Failed to get experience by ID: $e');
    }
  }

  /// Get average rating for an opportunity
  Future<double> getAverageRatingForOpportunity(String opportunityId) async {
    try {
      final experiences = await getExperiencesByOpportunity(opportunityId);
      
      if (experiences.isEmpty) {
        return 0.0;
      }
      
      final totalRating = experiences.fold<double>(0.0, (sum, exp) => sum + exp.rating);
      return totalRating / experiences.length;
    } catch (e) {
      throw Exception('Failed to get average rating: $e');
    }
  }

  /// Check if user has already posted experience for an opportunity
  Future<bool> hasUserPostedExperience(String userId, String opportunityId) async {
    try {
      final experienceData = await SupabaseService.selectSingle(
        'experiences',
        filters: {
          'user_id': userId,
          'opportunity_id': opportunityId,
        },
      );
      
      return experienceData != null;
    } catch (e) {
      throw Exception('Failed to check user experience: $e');
    }
  }
}