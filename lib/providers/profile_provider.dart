import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/user_profile.dart';
import '../core/network/auth_dio.dart';

class ProfileState {
  final UserProfile? profile;
  final ProfileSummary? summary;
  final bool isLoading;
  final String? error;

  ProfileState({this.profile, this.summary, this.isLoading = false, this.error});

  ProfileState copyWith({UserProfile? profile, ProfileSummary? summary, bool? isLoading, String? error}) {
    return ProfileState(
      profile: profile ?? this.profile,
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ProfileNotifier extends Notifier<ProfileState> {
  Dio get _dio => ref.read(authDioProvider);

  @override
  ProfileState build() {
    return ProfileState();
  }

  Future<void> loadProfile(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final resp = await _dio.get('/profiles/$userId');
      final profile = UserProfile.fromJson(resp.data);
      state = state.copyWith(profile: profile, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadSummary(String userId) async {
    try {
      final resp = await _dio.get('/profiles/$userId/summary');
      final summary = ProfileSummary.fromJson(resp.data);
      state = state.copyWith(summary: summary);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<bool> updateProfile(String userId, Map<String, dynamic> data) async {
    try {
      final resp = await _dio.patch('/profiles/$userId', data: data);
      final profile = UserProfile.fromJson(resp.data);
      state = state.copyWith(profile: profile);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, ProfileState>(ProfileNotifier.new);
