import '../models/opportunity.dart';
import '../models/user.dart';
import 'opportunity_service.dart';
import 'user_service.dart';

class MLRecommendationService {
  static final MLRecommendationService _instance = MLRecommendationService._internal();
  factory MLRecommendationService() => _instance;
  MLRecommendationService._internal();

  final OpportunityService _opportunityService = OpportunityService();

  /// Get personalized recommendations for a user
  Future<List<Opportunity>> getRecommendationsForUser(String userId) async {
    try {
      final user = await UserService.getProfile(userId);
      if (user == null) {
        throw Exception('User not found');
      }

      final allOpportunities = await _opportunityService.getAllOpportunities();
      final activeOpportunities = allOpportunities.where((opp) => opp.isActive).toList();

      // Calculate match scores for each opportunity
      final List<MapEntry<Opportunity, double>> scoredOpportunities = [];
      
      for (final opportunity in activeOpportunities) {
        final matchScore = calculateMatchScore(user, opportunity);
        if (matchScore >= 30.0) { // Minimum 30% match
          scoredOpportunities.add(MapEntry(opportunity, matchScore));
        }
      }

      // Sort by match score (highest first)
      scoredOpportunities.sort((a, b) => b.value.compareTo(a.value));

      // Return only the opportunities, sorted by recommendation score
      return scoredOpportunities.map((entry) => entry.key).toList();
    } catch (e) {
      throw Exception('Failed to get recommendations: $e');
    }
  }

  /// Calculate match score between user and opportunity
  double calculateMatchScore(User user, Opportunity opportunity) {
    try {
      double totalScore = 0.0;

      // Skills match: 40% weight
      final skillsScore = _calculateSkillsMatch(user.skills, opportunity.requiredSkills);
      totalScore += skillsScore * 0.4;

      // Location match: 30% weight
      final locationScore = _calculateLocationMatch(user.location, opportunity.location);
      totalScore += locationScore * 0.3;

      // Interest match: 30% weight
      final interestScore = _calculateInterestMatch(user.interests, opportunity.category);
      totalScore += interestScore * 0.3;

      return totalScore * 100; // Convert to percentage
    } catch (e) {
      // Return 0 if there's any error in calculation
      return 0.0;
    }
  }

  /// Calculate skills match score
  double _calculateSkillsMatch(List<String> userSkills, List<String> requiredSkills) {
    if (requiredSkills.isEmpty) {
      return 1.0; // If no skills required, full match
    }

    if (userSkills.isEmpty) {
      return 0.0; // If user has no skills, no match
    }

    // Convert to lowercase for case-insensitive comparison
    final userSkillsLower = userSkills.map((skill) => skill.toLowerCase()).toList();
    final requiredSkillsLower = requiredSkills.map((skill) => skill.toLowerCase()).toList();

    int matchingSkills = 0;
    for (final requiredSkill in requiredSkillsLower) {
      if (userSkillsLower.contains(requiredSkill)) {
        matchingSkills++;
      }
    }

    return matchingSkills / requiredSkills.length;
  }

  /// Calculate location match score
  double _calculateLocationMatch(String userLocation, String opportunityLocation) {
    if (userLocation.isEmpty || opportunityLocation.isEmpty) {
      return 0.5; // Neutral score if location info is missing
    }

    // Convert to lowercase for comparison
    final userLoc = userLocation.toLowerCase().trim();
    final oppLoc = opportunityLocation.toLowerCase().trim();

    // Remote work always matches
    if (oppLoc.contains('remote') || userLoc.contains('remote')) {
      return 1.0;
    }

    // Exact match
    if (userLoc == oppLoc) {
      return 1.0;
    }

    // Partial match (e.g., same city in different formats)
    if (userLoc.contains(oppLoc) || oppLoc.contains(userLoc)) {
      return 0.8;
    }

    // Check for common location keywords
    final userWords = userLoc.split(' ');
    final oppWords = oppLoc.split(' ');
    
    for (final userWord in userWords) {
      for (final oppWord in oppWords) {
        if (userWord.length > 2 && oppWord.length > 2 && userWord == oppWord) {
          return 0.6; // Partial match found
        }
      }
    }

    return 0.0; // No location match
  }

  /// Calculate interest match score
  double _calculateInterestMatch(List<String> userInterests, String opportunityCategory) {
    if (userInterests.isEmpty || opportunityCategory.isEmpty) {
      return 0.5; // Neutral score if interest info is missing
    }

    // Convert to lowercase for comparison
    final userInterestsLower = userInterests.map((interest) => interest.toLowerCase()).toList();
    final categoryLower = opportunityCategory.toLowerCase();

    // Direct category match
    if (userInterestsLower.contains(categoryLower)) {
      return 1.0;
    }

    // Check for partial matches or related terms
    for (final interest in userInterestsLower) {
      if (interest.contains(categoryLower) || categoryLower.contains(interest)) {
        return 0.8;
      }
    }

    // Check for related categories (basic keyword matching)
    final relatedTerms = _getRelatedTerms(categoryLower);
    for (final interest in userInterestsLower) {
      if (relatedTerms.contains(interest)) {
        return 0.6;
      }
    }

    return 0.0; // No interest match
  }

  /// Get related terms for a category (basic implementation)
  List<String> _getRelatedTerms(String category) {
    final Map<String, List<String>> relatedTermsMap = {
      'technology': ['tech', 'software', 'programming', 'development', 'it', 'computer'],
      'marketing': ['advertising', 'promotion', 'social media', 'content', 'digital'],
      'finance': ['accounting', 'banking', 'investment', 'money', 'economics'],
      'healthcare': ['medical', 'nursing', 'pharmacy', 'hospital', 'clinic'],
      'education': ['teaching', 'training', 'academic', 'school', 'university'],
      'design': ['creative', 'art', 'graphic', 'ui', 'ux', 'visual'],
      'sales': ['selling', 'business development', 'customer', 'retail'],
      'engineering': ['mechanical', 'electrical', 'civil', 'software engineering'],
      'research': ['analysis', 'study', 'investigation', 'science'],
      'consulting': ['advisory', 'strategy', 'management', 'business'],
    };

    return relatedTermsMap[category] ?? [];
  }

  /// Get recommendation explanation for debugging
  Map<String, dynamic> getRecommendationExplanation(User user, Opportunity opportunity) {
    final skillsScore = _calculateSkillsMatch(user.skills, opportunity.requiredSkills);
    final locationScore = _calculateLocationMatch(user.location, opportunity.location);
    final interestScore = _calculateInterestMatch(user.interests, opportunity.category);
    final totalScore = calculateMatchScore(user, opportunity);

    return {
      'totalScore': totalScore,
      'skillsScore': skillsScore * 100,
      'locationScore': locationScore * 100,
      'interestScore': interestScore * 100,
      'breakdown': {
        'skills': {
          'weight': 40,
          'score': skillsScore * 100,
          'userSkills': user.skills,
          'requiredSkills': opportunity.requiredSkills,
        },
        'location': {
          'weight': 30,
          'score': locationScore * 100,
          'userLocation': user.location,
          'opportunityLocation': opportunity.location,
        },
        'interest': {
          'weight': 30,
          'score': interestScore * 100,
          'userInterests': user.interests,
          'opportunityCategory': opportunity.category,
        },
      },
    };
  }
}