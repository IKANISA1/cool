import 'dart:async';

import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

/// Remote data source for authentication
///
/// Handles Supabase anonymous authentication.
abstract class AuthRemoteDataSource {
  /// Sign out current user
  Future<void> signOut();

  /// Get current user
  Future<UserModel?> getCurrentUser();

  /// Stream of auth state changes
  Stream<UserModel?> get authStateChanges;

  /// Sign in anonymously
  Future<UserModel> signInAnonymously();
}

/// Implementation of [AuthRemoteDataSource] using Supabase
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  static final _log = Logger('AuthRemoteDataSource');

  final supabase.SupabaseClient _client;

  AuthRemoteDataSourceImpl(this._client);

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      _log.info('User signed out');
    } catch (e, stackTrace) {
      _log.severe('Failed to sign out', e, stackTrace);
      throw ServerException(message: 'Failed to sign out: $e');
    }
  }

  @override
  Future<UserModel> signInAnonymously() async {
    try {
      final response = await _client.auth.signInAnonymously();
      
      if (response.user == null) {
        throw const AuthException(message: 'Failed to create anonymous user');
      }

      final user = response.user!;
      return UserModel.fromSupabase(
        user: {
          'id': user.id,
          'phone': user.phone,
          'created_at': user.createdAt,
          'is_anonymous': user.isAnonymous,
        },
      );
    } on supabase.AuthException catch (e) {
      _log.warning('Auth error signing in anonymously: ${e.message}');
      throw AuthException(message: e.message, code: e.statusCode?.toString());
    } catch (e, stackTrace) {
      _log.severe('Failed to sign in anonymously', e, stackTrace);
      throw ServerException(message: 'Failed to sign in anonymously: $e');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final profile = await _fetchProfile(user.id);

      return UserModel.fromSupabase(
        user: {
          'id': user.id,
          'phone': user.phone,
          'created_at': user.createdAt,
          'is_anonymous': user.isAnonymous,
        },
        profile: profile,
      );
    } catch (e, stackTrace) {
      _log.warning('Failed to get current user', e, stackTrace);
      return null;
    }
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return _client.auth.onAuthStateChange.asyncMap((state) async {
      if (state.session?.user == null) return null;

      final user = state.session!.user;
      
      // Fetch profile with timeout to prevent blocking auth flow indefinitely
      Map<String, dynamic>? profile;
      try {
        profile = await _fetchProfile(user.id).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            _log.warning('Profile fetch timed out for user ${user.id}');
            return null;
          },
        );
      } catch (e) {
        _log.warning('Error fetching profile on auth state change: $e');
        profile = null;
      }

      return UserModel.fromSupabase(
        user: {
          'id': user.id,
          'phone': user.phone,
          'created_at': user.createdAt,
          'is_anonymous': user.isAnonymous,
        },
        profile: profile,
      );
    });
  }

  /// Fetch user profile from database
  Future<Map<String, dynamic>?> _fetchProfile(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      _log.warning('Failed to fetch profile for $userId: $e');
      return null;
    }
  }
}
