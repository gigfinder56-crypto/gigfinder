import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase/supabase_config.dart';
import '../models/opportunity.dart';

class OpportunityService {
  static final OpportunityService _instance = OpportunityService._internal();
  factory OpportunityService() => _instance;
  OpportunityService._internal();

  static const Uuid _uuid = Uuid();

  /// Get all active opportunities
  Future<List<Opportunity>> getAllOpportunities() async {
    try {
      final data = await SupabaseService.select(
        'opportunities',
        filters: {'is_active': true},
        orderBy: 'posted_date',
        ascending: false,
      );

      return data.map((json) => Opportunity.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get all opportunities: $e');
    }
  }

  /// ✅ Get opportunities filtered by category (case-insensitive)
  Future<List<Opportunity>> getOpportunitiesByCategory(String category) async {
    try {
      final response = await Supabase.instance.client
          .from('opportunities')
          .select()
          .ilike('category', category) // ✅ Fix: case-insensitive search
          .eq('is_active', true)
          .order('posted_date', ascending: false);

      return (response as List)
          .map((json) => Opportunity.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get opportunities by category: $e');
    }
  }

  /// Get a single opportunity by ID
  Future<Opportunity?> getOpportunityById(String id) async {
    try {
      final data = await SupabaseService.selectSingle(
        'opportunities',
        filters: {'id': id},
      );

      return data != null ? Opportunity.fromJson(data) : null;
    } catch (e) {
      throw Exception('Failed to get opportunity by ID: $e');
    }
  }

  /// Create a new opportunity (admin function)
  Future<void> createOpportunity(Opportunity opportunity) async {
    try {
      final newOpportunity = opportunity.copyWith(
        id: _uuid.v4(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await SupabaseService.insert('opportunities', newOpportunity.toJson());
    } catch (e) {
      throw Exception('Failed to create opportunity: $e');
    }
  }

  /// Update an existing opportunity (admin function)
  Future<void> updateOpportunity(Opportunity opportunity) async {
    try {
      final updatedOpportunity = opportunity.copyWith(updatedAt: DateTime.now());

      final result = await SupabaseService.update(
        'opportunities',
        updatedOpportunity.toJson(),
        filters: {'id': opportunity.id},
      );

      if (result.isEmpty) {
        throw Exception('Opportunity not found');
      }
    } catch (e) {
      throw Exception('Failed to update opportunity: $e');
    }
  }

  /// Soft delete an opportunity by setting isActive to false
  Future<void> deleteOpportunity(String id) async {
    try {
      final result = await SupabaseService.update(
        'opportunities',
        {
          'is_active': false,
          'updated_at': DateTime.now().toIso8601String(),
        },
        filters: {'id': id},
      );

      if (result.isEmpty) {
        throw Exception('Opportunity not found');
      }
    } catch (e) {
      throw Exception('Failed to delete opportunity: $e');
    }
  }

  /// Search opportunities by query in title, company, description, or skills
  Future<List<Opportunity>> searchOpportunities(String query) async {
    try {
      final data = await SupabaseService.select(
        'opportunities',
        filters: {'is_active': true},
        orderBy: 'posted_date',
        ascending: false,
      );

      final opportunities = data.map((json) => Opportunity.fromJson(json)).toList();
      final lowerQuery = query.toLowerCase();

      return opportunities.where((opportunity) {
        return opportunity.title.toLowerCase().contains(lowerQuery) ||
            opportunity.company.toLowerCase().contains(lowerQuery) ||
            opportunity.description.toLowerCase().contains(lowerQuery) ||
            opportunity.requiredSkills.any(
              (skill) => skill.toLowerCase().contains(lowerQuery),
            );
      }).toList();
    } catch (e) {
      throw Exception('Failed to search opportunities: $e');
    }
  }
}
