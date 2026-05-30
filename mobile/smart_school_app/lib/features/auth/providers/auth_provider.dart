import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/user_model.dart';
import '../../../services/supabase_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isOffline = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get isOffline => _isOffline;

  AuthProvider() {
    // Initialize connectivity monitoring
    Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
    
    // Listen for auth changes
    SupabaseService.authStateChanges().listen((AuthState state) {
      if (state.event == AuthChangeEvent.signedIn) {
        _getUserProfile();
      } else if (state.event == AuthChangeEvent.signedOut) {
        _user = null;
        notifyListeners();
      }
    });
  }

  void _updateConnectionStatus(ConnectivityResult result) async {
    final wasOffline = _isOffline;
    _isOffline = result == ConnectivityResult.none;
    
    // If we went from offline to online, try to restore the session
    if (wasOffline && !_isOffline && _user != null) {
      try {
        await Future.delayed(const Duration(seconds: 2)); // Give network time to stabilize
        await _attemptSessionRefresh();
      } catch (e) {
        print("Failed to refresh session after reconnection: $e");
      }
    }
    
    notifyListeners();
  }
  
  Future<void> _attemptSessionRefresh() async {
    try {
      await SupabaseService.client.auth.refreshSession();
      print("Session refreshed successfully after reconnection");
    } catch (e) {
      print("Session refresh failed: $e");
      // If refresh fails critically, we may need to sign out
      if (e is AuthException && (e.message.contains('expired') || e.message.contains('invalid'))) {
        await signOut();
      }
    }
  }

  Future<void> _getUserProfile() async {
    try {
      final user = SupabaseService.getCurrentUser();
      if (user != null) {
        try {
          // First try with UUID string directly
          final response = await SupabaseService.client
              .from('users')
              .select()
              .eq('user_id', user.id)
              .single();
          
          _user = UserModel.fromJson({
            'id': user.id,
            'email': user.email ?? '',
            'name': response['name'] ?? '',
            'role': response['role'] ?? 'teacher',
          });
          
          notifyListeners();
        } catch (e) {
          print("Error fetching user profile: $e");
          // Fallback to creating a basic user profile from session data
          _user = UserModel.fromJson({
            'id': user.id,
            'email': user.email ?? '',
            'name': user.email?.split('@')[0] ?? 'User',
            'role': 'teacher', // Default role
          });
          notifyListeners();
        }
      }
    } on SocketException catch (e) {
      print("Network error while getting user profile: $e");
      _isOffline = true;
      _errorMessage = 'Network connection issue. Please check your internet.';
      notifyListeners();
    } catch (e) {
      print("General error in _getUserProfile: $e");
      _errorMessage = 'Failed to get user profile: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check connection first
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        throw SocketException('No internet connection available.');
      }
      
      await SupabaseService.signIn(email, password);
      await _getUserProfile();
      _isLoading = false;
      _isOffline = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _isLoading = false;
      _errorMessage = 'Authentication error: ${e.message}';
      notifyListeners();
      return false;
    } on SocketException catch (e) {
      _isLoading = false;
      _isOffline = true;
      _errorMessage = 'Network error: Please check your internet connection';
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Sign in failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await SupabaseService.signOut();
      _user = null;
    } on SocketException catch (e) {
      // Still clear the user locally even if network fails
      _user = null;
      _errorMessage = 'Network error during sign out. You\'ve been signed out locally.';
      _isOffline = true;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check connection first
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        throw SocketException('No internet connection available.');
      }
      
      await SupabaseService.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } on SocketException catch (e) {
      _isLoading = false;
      _isOffline = true;
      _errorMessage = 'Network error: Please check your internet connection';
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> initializeAuth() async {
    try {
      print("Starting initializeAuth...");
      
      // Check connection first
      var connectivityResult = await Connectivity().checkConnectivity();
      _isOffline = connectivityResult == ConnectivityResult.none;
      
      if (_isOffline) {
        print("Device is offline, attempting to use cached session");
      }
      
      // Check for an existing session
      final session = SupabaseService.client.auth.currentSession;
      
      if (session != null) {
        print("Session found: ${session.user.id}");
        
        // Create user from session data
        _user = UserModel.fromJson({
          'id': session.user.id,
          'email': session.user.email ?? '',
          'name': session.user.email?.split('@')[0] ?? 'User',
          'role': 'teacher', // Default role
        });
        
        // Only attempt to fetch additional user data if we're online
        if (!_isOffline) {
          try {
            print("Fetching user data for user_id: ${session.user.id}");
            final userData = await SupabaseService.client
                .from('users')
                .select()
                .eq('user_id', session.user.id)
                .single();
                
            print("User data fetched: ${userData.toString()}");
            
            // Update user with complete data
            _user = UserModel.fromJson({
              'id': session.user.id,
              'email': session.user.email ?? '',
              'name': userData['name'] ?? _user?.name ?? '',
              'role': userData['role'] ?? _user?.role ?? 'teacher',
            });
          } catch (dbError) {
            print("Database error: $dbError");
            // We already have basic user data from session, no need to recreate
          }
        }
      } else {
        print("No session found");
        _user = null;
      }
    } on SocketException catch (e) {
      print("Network error in initializeAuth: $e");
      _isOffline = true;
      // Don't set error message here - just gracefully handle offline state
    } catch (e) {
      print("Error in initializeAuth: $e");
      _errorMessage = e.toString();
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
      print("initializeAuth complete. User: ${_user != null ? 'logged in' : 'logged out'}, Offline: $_isOffline");
    }
  }

  // Method to manually retry connection
  Future<bool> retryConnection() async {
    if (!_isOffline) return true;
    
    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      _isOffline = connectivityResult == ConnectivityResult.none;
      
      if (!_isOffline) {
        await _attemptSessionRefresh();
      }
      
      notifyListeners();
      return !_isOffline;
    } catch (e) {
      print("Error retrying connection: $e");
      return false;
    }
  }

  Future<void> updateUserProfile({String? name}) async {
    try {
      // Update user metadata in Supabase
      final response = await SupabaseService.client.auth.updateUser(
        UserAttributes(
          data: {'name': name},  // This is correct for user_metadata
        ),
      );
      
      if (response.user != null) {
        // Update the local user model
        _user = UserModel.fromJson({
          'id': response.user!.id,
          'email': response.user!.email,
          'name': name ?? _user?.name,
          'role': _user?.role ?? 'teacher',
        });
        
        // Also update the user profile in the 'profiles' table if you have one
        await _updateUserProfileInDatabase(name);
        
        notifyListeners();
      } else {
        throw Exception('Failed to update user profile');
      }
    } catch (e) {
      _errorMessage = 'Failed to update profile: ${e.toString()}';
      notifyListeners();
      throw e;
    }
  }

  // Add this helper method to update the database profile
  Future<void> _updateUserProfileInDatabase(String? name) async {
    try {
      if (_user == null) return;
      
      // Update the profiles table (create it if you don't have one)
      await SupabaseService.client
          .from('users')  // You might need to change this to your actual table name
          .upsert({
            'user_id': _user!.id,  // Use the user's ID as the primary key
            'name': name,
            'updated_at': DateTime.now().toIso8601String(),
          });
          
    } catch (e) {
      print('Error updating profile in database: $e');
      // Don't throw here, we already updated Auth metadata
    }
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print("Starting signup process for: $email");
      
      // Check connection first
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        throw SocketException('No internet connection available.');
      }
      
      print("About to call Supabase signUp");
      // Register the user using Supabase Auth
      final response = await SupabaseService.client.auth.signUp(
        email: email.trim(), // ⬅️ Make sure to trim the email
        password: password,
        data: {
          'name': name,
          'role': role
        },
      );
      
      print("SignUp response received: ${response.user != null ? 'User created' : 'No user in response'}");
      
      if (response.user != null) {
        // Create a user record in your 'users' table
        await SupabaseService.client.from('users').upsert({
          'user_id': response.user!.id,
          'email': email,
          'name': name,
          'role': role,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // The response.user is null but we might not have an error - this is a sign-up
        // so the user may need to confirm their email
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on AuthException catch (e) {
      _isLoading = false;
      
      // More user-friendly error messages
      if (e.message.contains("invalid") && e.message.contains("email")) {
        _errorMessage = 'Please use a different email address. This one cannot be used.';
      } else if (e.message.contains("already in use") || e.message.contains("exists")) {
        _errorMessage = 'An account with this email already exists. Please sign in instead.';
      } else {
        _errorMessage = 'Authentication error: ${e.message}';
      }
      
      notifyListeners();
      return false;
    } on SocketException catch (e) {
      _isLoading = false;
      _isOffline = true;
      _errorMessage = 'Network error: Please check your internet connection';
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Sign up failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
}