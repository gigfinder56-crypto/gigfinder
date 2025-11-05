// Authentication Manager - Base interface for auth implementations
//
// This abstract class and mixins define the contract for authentication systems.
// Implement this with concrete classes for Firebase, Supabase, or local auth.
//
// Usage:
// 1. Create a concrete class extending AuthManager
// 2. Mix in the required authentication provider mixins
// 3. Implement all abstract methods with your auth provider logic

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:mavenlink/models/user.dart';
import 'package:mavenlink/supabase/supabase_config.dart';

// Core authentication operations that all auth implementations must provide
abstract class AuthManager {
  Future signOut();
  Future deleteUser(BuildContext context);
  Future updateEmail({required String email, required BuildContext context});
  Future resetPassword({required String email, required BuildContext context});
  
  // Get current authenticated user
  Future<User?> getCurrentUser();
  
  // Check if user is authenticated
  bool get isAuthenticated;
  
  // Get auth user ID
  String? get currentUserId;
}

// Email/password authentication mixin
mixin EmailSignInManager on AuthManager {
  Future<User?> signInWithEmail(
    BuildContext context,
    String email,
    String password,
  );

  Future<User?> createAccountWithEmail(
    BuildContext context,
    String email,
    String password,
  );
}

// Anonymous authentication for guest users
mixin AnonymousSignInManager on AuthManager {
  Future<User?> signInAnonymously(BuildContext context);
}

// Apple Sign-In authentication (iOS/web)
mixin AppleSignInManager on AuthManager {
  Future<User?> signInWithApple(BuildContext context);
}

// Google Sign-In authentication (all platforms)
mixin GoogleSignInManager on AuthManager {
  Future<User?> signInWithGoogle(BuildContext context);
}

// JWT token authentication for custom backends
mixin JwtSignInManager on AuthManager {
  Future<User?> signInWithJwtToken(
    BuildContext context,
    String jwtToken,
  );
}

// Phone number authentication with SMS verification
mixin PhoneSignInManager on AuthManager {
  Future beginPhoneAuth({
    required BuildContext context,
    required String phoneNumber,
    required void Function(BuildContext) onCodeSent,
  });

  Future verifySmsCode({
    required BuildContext context,
    required String smsCode,
  });
}

// Facebook Sign-In authentication
mixin FacebookSignInManager on AuthManager {
  Future<User?> signInWithFacebook(BuildContext context);
}

// Microsoft Sign-In authentication (Azure AD)
mixin MicrosoftSignInManager on AuthManager {
  Future<User?> signInWithMicrosoft(
    BuildContext context,
    List<String> scopes,
    String tenantId,
  );
}

// GitHub Sign-In authentication (OAuth)
mixin GithubSignInManager on AuthManager {
  Future<User?> signInWithGithub(BuildContext context);
}

// Supabase Authentication Implementation
class SupabaseAuthManager extends AuthManager with EmailSignInManager {
  
  @override
  bool get isAuthenticated => SupabaseConfig.auth.currentUser != null;
  
  @override
  String? get currentUserId => SupabaseConfig.auth.currentUser?.id;
  
  @override
  Future<User?> getCurrentUser() async {
    final authUser = SupabaseConfig.auth.currentUser;
    if (authUser == null) return null;
    
    try {
      final data = await SupabaseService.selectSingle(
        'users',
        filters: {'id': authUser.id},
      );
      
      if (data != null) {
        return User.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }
  
  @override
  Future<User?> signInWithEmail(
    BuildContext context,
    String email,
    String password,
  ) async {
    try {
      final response = await SupabaseConfig.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        // User data will be loaded later in the navigation flow
        return null;
      }
      throw Exception('Sign in failed');
    } on sb.AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }
  
  @override
  Future<User?> createAccountWithEmail(
    BuildContext context,
    String email,
    String password,
  ) async {
    try {
      final response = await SupabaseConfig.auth.signUp(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        // Create user record in users table
        await SupabaseService.insert('users', {
          'id': response.user!.id,
          'email': email,
          'name': '',
          'age': 0,
          'profile_photo_path': '',
          'mobile_number': '',
          'skills': [],
          'interests': [],
          'resume_path': '',
          'role': '',
          'location': '',
          'others': '',
          'is_profile_complete': false,
          'is_admin': false,
        });
        
        // User data will be loaded later in the navigation flow
        return null;
      }
      throw Exception('Sign up failed');
    } on sb.AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }
  
  @override
  Future signOut() async {
    try {
      await SupabaseConfig.auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }
  
  @override
  Future deleteUser(BuildContext context) async {
    try {
      final user = SupabaseConfig.auth.currentUser;
      if (user == null) throw Exception('No user logged in');
      
      // Delete user record from users table (cascade will handle related records)
      await SupabaseService.delete('users', filters: {'id': user.id});
      
      // Sign out
      await signOut();
    } catch (e) {
      throw Exception('Delete user failed: $e');
    }
  }
  
  @override
  Future updateEmail({required String email, required BuildContext context}) async {
    try {
      await SupabaseConfig.auth.updateUser(sb.UserAttributes(email: email));
      
      // Update email in users table
      final userId = currentUserId;
      if (userId != null) {
        await SupabaseService.update(
          'users',
          {'email': email},
          filters: {'id': userId},
        );
      }
    } on sb.AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Update email failed: $e');
    }
  }
  
  @override
  Future resetPassword({required String email, required BuildContext context}) async {
    try {
      await SupabaseConfig.auth.resetPasswordForEmail(email);
    } on sb.AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Reset password failed: $e');
    }
  }
}
