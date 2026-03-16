import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/digital_form.dart';
import '../core/network/auth_dio.dart';
import '../core/utils/error_helper.dart';

class FormState {
  final List<FormTemplate> templates;
  final List<FormSubmission> submissions;
  final bool isLoading;
  final String? error;

  FormState({this.templates = const [], this.submissions = const [], this.isLoading = false, this.error});

  FormState copyWith({List<FormTemplate>? templates, List<FormSubmission>? submissions, bool? isLoading, String? error}) {
    return FormState(
      templates: templates ?? this.templates,
      submissions: submissions ?? this.submissions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class FormNotifier extends Notifier<FormState> {
  Dio get _dio => ref.read(authDioProvider);

  @override
  FormState build() {
    return FormState();
  }

  Future<void> loadTemplates(String userId, {String? category}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final params = <String, dynamic>{'user_id': userId};
      if (category != null) params['category'] = category;
      final resp = await _dio.get('/forms/templates', queryParameters: params);
      final items = (resp.data as List).map((j) => FormTemplate.fromJson(j)).toList();
      state = state.copyWith(templates: items, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorHelper.getMessage(e));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorHelper.getMessage(e));
    }
  }

  Future<void> loadSubmissions(String userId) async {
    try {
      final resp = await _dio.get('/forms/submissions', queryParameters: {'user_id': userId});
      final items = (resp.data as List).map((j) => FormSubmission.fromJson(j)).toList();
      state = state.copyWith(submissions: items);
    } on DioException catch (e) {
      state = state.copyWith(error: ErrorHelper.getMessage(e));
    } catch (e) {
      state = state.copyWith(error: ErrorHelper.getMessage(e));
    }
  }

  Future<bool> submitForm({required String templateId, required String userId, required Map<String, dynamic> data}) async {
    try {
      await _dio.post('/forms/submissions', data: {
        'template_id': templateId,
        'user_id': userId,
        'data': data,
        'status': 'submitted',
      });
      await loadTemplates(userId);
      await loadSubmissions(userId);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(error: ErrorHelper.getMessage(e));
      return false;
    } catch (e) {
      state = state.copyWith(error: ErrorHelper.getMessage(e));
      return false;
    }
  }
}

final formProvider = NotifierProvider<FormNotifier, FormState>(FormNotifier.new);
