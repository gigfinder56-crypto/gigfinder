import '../models/user.dart';
import '../supabase/supabase_config.dart';
import 'auth_service.dart';

class UserService {
  // Create a new user profile
  static Future<bool> createProfile(User user) async {
    try {
      // Check if user already exists
      final existingUser = await SupabaseService.selectSingle(
        'users',
        filters: {'id': user.id},
      );

      if (existingUser != null) {
        throw Exception('User profile already exists');
      }

      // Add new user
      final updatedUser = user.copyWith(
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await SupabaseService.insert('users', updatedUser.toJson());
      
      return true;
    } catch (e) {
      print('Failed to create profile: $e');
      return false;
    }
  }

  // Update an existing user profile
  static Future<bool> updateProfile(User user) async {
    try {
      // Update with current timestamp
      final updatedUser = user.copyWith(updatedAt: DateTime.now());
      
      final result = await SupabaseService.update(
        'users',
        updatedUser.toJson(),
        filters: {'id': user.id},
      );

      if (result.isEmpty) {
        throw Exception('User not found');
      }

      return true;
    } catch (e) {
      print('Failed to update profile: $e');
      return false;
    }
  }

  // Get user profile by ID
  static Future<User?> getProfile(String userId) async {
    try {
      if (userId.isEmpty) {
        throw Exception('User ID cannot be empty');
      }

      final userData = await SupabaseService.selectSingle(
        'users',
        filters: {'id': userId},
      );
      
      return userData != null ? User.fromJson(userData) : null;
    } catch (e) {
      print('Failed to get profile: $e');
      return null;
    }
  }

  // Get all users (admin only functionality)
  static Future<List<User>> getAllUsers() async {
    try {
      final usersData = await SupabaseService.select('users');
      
      return usersData.map((userData) => User.fromJson(userData)).toList();
    } catch (e) {
      print('Failed to get all users: $e');
      return [];
    }
  }

  // Check if user profile is complete
  static Future<bool> isProfileComplete(String userId) async {
    try {
      final user = await getProfile(userId);
      if (user == null) {
        return false;
      }

      // Check essential profile fields
      return user.name.isNotEmpty &&
             user.email.isNotEmpty &&
             user.age > 0 &&
             user.mobileNumber.isNotEmpty &&
             user.location.isNotEmpty &&
             user.role.isNotEmpty &&
             (user.studentInfo != null || user.employeeInfo != null);
    } catch (e) {
      print('Failed to check profile completeness: $e');
      return false;
    }
  }

  // Get currently logged in user
  static Future<User?> getCurrentUser() async {
    try {
      final currentUserId = AuthService.getCurrentUserId();
      if (currentUserId == null || currentUserId.isEmpty) {
        return null;
      }

      return await getProfile(currentUserId);
    } catch (e) {
      print('Failed to get current user: $e');
      return null;
    }
  }

  // Update profile completion status
  static Future<bool> updateProfileCompletionStatus(String userId) async {
    try {
      final user = await getProfile(userId);
      if (user == null) {
        throw Exception('User not found');
      }

      final isComplete = await isProfileComplete(userId);
      if (user.isProfileComplete != isComplete) {
        final updatedUser = user.copyWith(
          isProfileComplete: isComplete,
          updatedAt: DateTime.now(),
        );
        return await updateProfile(updatedUser);
      }

      return true;
    } catch (e) {
      print('Failed to update profile completion status: $e');
      return false;
    }
  }

  // Search users by name or email (for admin functionality)
  static Future<List<User>> searchUsers(String query) async {
    try {
      if (query.isEmpty) {
        return [];
      }

      final usersData = await SupabaseService.select(
        'users',
        orderBy: 'name',
      );
      
      final users = usersData.map((userData) => User.fromJson(userData)).toList();
      final lowercaseQuery = query.toLowerCase();

      return users.where((user) {
        return user.name.toLowerCase().contains(lowercaseQuery) ||
               user.email.toLowerCase().contains(lowercaseQuery);
      }).toList();
    } catch (e) {
      print('Failed to search users: $e');
      return [];
    }
  }

  // Get users by role (Student/Employee)
  static Future<List<User>> getUsersByRole(String role) async {
    try {
      final usersData = await SupabaseService.select(
        'users',
        filters: {'role': role},
        orderBy: 'name',
      );
      
      return usersData.map((userData) => User.fromJson(userData)).toList();
    } catch (e) {
      print('Failed to get users by role: $e');
      return [];
    }
  }

  // Delete user profile (admin functionality)
  static Future<bool> deleteProfile(String userId) async {
    try {
      if (userId.isEmpty) {
        throw Exception('User ID cannot be empty');
      }

      // Check if user exists before deleting
      final user = await getProfile(userId);
      if (user == null) {
        throw Exception('User not found');
      }

      await SupabaseService.delete(
        'users',
        filters: {'id': userId},
      );
      
      // Note: AuthService handles logout if needed
      
      return true;
    } catch (e) {
      print('Failed to delete profile: $e');
      return false;
    }
  }

  // Get user statistics (admin functionality)
  static Future<Map<String, int>> getUserStats() async {
    try {
      final usersData = await SupabaseService.select('users');
      final users = usersData.map((userData) => User.fromJson(userData)).toList();
      
      int totalUsers = users.length;
      int completedProfiles = 0;
      int students = 0;
      int employees = 0;
      int admins = 0;

      for (var user in users) {
        if (user.isProfileComplete) completedProfiles++;
        if (user.isAdmin) admins++;
        if (user.role.toLowerCase() == 'student') students++;
        if (user.role.toLowerCase() == 'employee') employees++;
      }

      return {
        'total': totalUsers,
        'completed': completedProfiles,
        'students': students,
        'employees': employees,
        'admins': admins,
      };
    } catch (e) {
      print('Failed to get user statistics: $e');
      return {
        'total': 0,
        'completed': 0,
        'students': 0,
        'employees': 0,
        'admins': 0,
      };
    }
  }
}