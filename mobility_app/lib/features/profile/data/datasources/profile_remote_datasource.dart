import 'dart:io';

import '../../../../core/error/exceptions.dart';
import '../../../../features/profile/data/models/profile_model.dart';
import '../../../../features/profile/domain/entities/profile.dart'; // For Enums
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:logging/logging.dart';

abstract class ProfileRemoteDataSource {
  Future<ProfileModel> getProfile();
  Future<ProfileModel> getProfileById(String userId);
  Future<ProfileModel> createProfile({
    required String name,
    required UserRole role,
    required String countryCode,
    List<String> languages = const [],
    VehicleCategory? vehicleCategory,
    String? avatarUrl,
    String? phoneNumber,
  });
  Future<ProfileModel> updateProfile({
    String? name,
    UserRole? role,
    String? countryCode,
    List<String>? languages,
    VehicleCategory? vehicleCategory,
    String? avatarUrl,
    String? phoneNumber,
  });
  Future<bool> hasProfile();
  Future<String> uploadAvatar(String filePath);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  static final _log = Logger('ProfileRemoteDataSource');
  final supabase.SupabaseClient _client;

  ProfileRemoteDataSourceImpl(this._client);

  @override
  Future<ProfileModel> getProfile() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw const AuthException(message: 'User not logged in');

      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      
      return ProfileModel.fromJson(data);
    } catch (e, stackTrace) {
      _log.severe('Error getting profile', e, stackTrace);
      if (e is supabase.AuthException) rethrow; // Pass auth exceptions
      throw ServerException(message: 'Failed to get profile');
    }
  }

  @override
  Future<ProfileModel> getProfileById(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      
      return ProfileModel.fromJson(data);
    } catch (e, stackTrace) {
      _log.severe('Error getting profile by ID', e, stackTrace);
      throw ServerException(message: 'Failed to get profile');
    }
  }
  
  @override
  Future<bool> hasProfile() async {
     try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      final data = await _client
          .from('profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      
      return data != null;
    } catch (e, stackTrace) {
      _log.warning('Error checking profile existence', e, stackTrace);
      return false;
    }
  }

  @override
  Future<ProfileModel> createProfile({
    required String name,
    required UserRole role,
    required String countryCode,
    List<String> languages = const [],
    VehicleCategory? vehicleCategory,
    String? avatarUrl,
    String? phoneNumber,
  }) async {
    try {
       final userId = _client.auth.currentUser?.id;
      if (userId == null) throw const AuthException(message: 'User not logged in');

      // Prepare data - only include columns that exist in the profiles table
      // Core columns: id, name, role, country, languages, avatar_url, verified
      final profileData = <String, dynamic>{
        'id': userId,
        'name': name.isEmpty ? 'User' : name, // Default name if empty
        'role': role.name,
        'country': countryCode,
        'languages': languages,
        'avatar_url': avatarUrl,
        'verified': false, // Default
      };

      final data = await _client
          .from('profiles')
          .upsert(profileData, onConflict: 'id')
          .select()
          .single();
          
       return ProfileModel.fromJson(data);
    } catch (e, stackTrace) {
      _log.severe('Error creating profile', e, stackTrace);
      throw ServerException(message: 'Failed to create profile');
    }
  }

  @override
  Future<ProfileModel> updateProfile({
    String? name,
    UserRole? role,
    String? countryCode,
    List<String>? languages,
    VehicleCategory? vehicleCategory,
    String? avatarUrl,
    String? phoneNumber,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw const AuthException(message: 'User not logged in');

      final updates = ProfileModel.toUpdateJson(
        name: name,
        role: role,
        countryCode: countryCode,
        languages: languages,
        vehicleCategory: vehicleCategory,
        avatarUrl: avatarUrl,
        phoneNumber: phoneNumber,
      );

      final data = await _client
          .from('profiles')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();
          
       return ProfileModel.fromJson(data);
    } catch (e, stackTrace) {
      _log.severe('Error updating profile', e, stackTrace);
      throw ServerException(message: 'Failed to update profile');
    }
  }

  @override
  Future<String> uploadAvatar(String filePath) async {
    try {
       final userId = _client.auth.currentUser?.id;
      if (userId == null) throw const AuthException(message: 'User not logged in');

      final file = File(filePath);
      final fileExt = filePath.split('.').last;
      final fileName = '$userId/avatar.${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await _client.storage
          .from('avatars')
          .upload(fileName, file);
      
      final publicUrl = _client.storage
          .from('avatars')
          .getPublicUrl(fileName);
          
      return publicUrl;
    } catch (e, stackTrace) {
      _log.severe('Error uploading avatar', e, stackTrace);
      throw ServerException(message: 'Failed to upload avatar');
    }
  }
}
