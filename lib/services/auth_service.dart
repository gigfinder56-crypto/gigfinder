import 'package:flutter/material.dart';
import 'package:mavenlink/auth/auth_manager.dart';
import 'package:mavenlink/models/user.dart';

class AuthService {
  static final SupabaseAuthManager _authManager = SupabaseAuthManager();

  // Sign in with email and password
  static Future<String?> signIn(BuildContext context, String email, String password) async {
    try {
      await _authManager.signInWithEmail(context, email, password);
      return _authManager.currentUserId;
    } catch (e) {
      print('Sign in failed: $e');
      rethrow;
    }
  }

  // Sign up with email and password
  static Future<String?> signUp(BuildContext context, String email, String password) async {
    try {
      await _authManager.createAccountWithEmail(context, email, password);
      return _authManager.currentUserId;
    } catch (e) {
      print('Sign up failed: $e');
      rethrow;
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      await _authManager.signOut();
    } catch (e) {
      print('Sign out failed: $e');
      rethrow;
    }
  }

  // Get current user ID
  static String? getCurrentUserId() => _authManager.currentUserId;

  // Get current user
  static Future<User?> getCurrentUser() async {
    try {
      return await _authManager.getCurrentUser();
    } catch (e) {
      print('Failed to get current user: $e');
      return null;
    }
  }

  // Check if user is authenticated
  static bool isAuthenticated() => _authManager.isAuthenticated;

  // Reset password
  static Future<void> resetPassword(BuildContext context, String email) async {
    try {
      await _authManager.resetPassword(email: email, context: context);
    } catch (e) {
      print('Reset password failed: $e');
      rethrow;
    }
  }

  // Update email
  static Future<void> updateEmail(BuildContext context, String email) async {
    try {
      await _authManager.updateEmail(email: email, context: context);
    } catch (e) {
      print('Update email failed: $e');
      rethrow;
    }
  }

  // Delete user
  static Future<void> deleteUser(BuildContext context) async {
    try {
      await _authManager.deleteUser(context);
    } catch (e) {
      print('Delete user failed: $e');
      rethrow;
    }
  }
}
