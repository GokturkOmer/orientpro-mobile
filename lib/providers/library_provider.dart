import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/library_document.dart';
import '../core/network/auth_dio.dart';

// State
class LibraryState {
  final List<LibraryDocument> personalDocs;
  final List<LibraryDocument> sharedDocs;
  final bool isLoading;
  final String? error;

  LibraryState({this.personalDocs = const [], this.sharedDocs = const [], this.isLoading = false, this.error});

  LibraryState copyWith({List<LibraryDocument>? personalDocs, List<LibraryDocument>? sharedDocs, bool? isLoading, String? error}) {
    return LibraryState(
      personalDocs: personalDocs ?? this.personalDocs,
      sharedDocs: sharedDocs ?? this.sharedDocs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Notifier
class LibraryNotifier extends Notifier<LibraryState> {
  Dio get _dio => ref.read(authDioProvider);

  @override
  LibraryState build() {
    return LibraryState();
  }

  Future<void> loadPersonalDocs(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final resp = await _dio.get('/library/personal/$userId');
      final docs = (resp.data as List).map((j) => LibraryDocument.fromJson(j)).toList();
      state = state.copyWith(personalDocs: docs, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadSharedDocs({String? department, String? docType}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final params = <String, dynamic>{};
      if (department != null) params['department'] = department;
      if (docType != null) params['doc_type'] = docType;
      final resp = await _dio.get('/library/shared', queryParameters: params);
      final docs = (resp.data as List).map((j) => LibraryDocument.fromJson(j)).toList();
      state = state.copyWith(sharedDocs: docs, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> uploadDocument({
    required String title,
    required String category,
    required String docType,
    required String userId,
    required String fileName,
    required List<int> fileBytes,
    required String mimeType,
    String? description,
    String? department,
  }) async {
    try {
      // 1. Upload file to MinIO
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
      });
      final uploadResp = await _dio.post('/files/upload?bucket=${category == "personal" ? "personal-docs" : "shared-library"}', data: formData);
      final uploadData = uploadResp.data;

      // 2. Create library record
      await _dio.post('/library/', data: {
        'title': title,
        'description': description,
        'category': category,
        'doc_type': docType,
        'department': department,
        'file_url': uploadData['file_url'],
        'file_name': uploadData['file_name'],
        'file_size': uploadData['file_size'],
        'mime_type': uploadData['mime_type'],
        'uploaded_by': userId,
      });

      // 3. Refresh list
      if (category == 'personal') {
        await loadPersonalDocs(userId);
      } else {
        await loadSharedDocs(department: department);
      }
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteDocument(String docId, String userId) async {
    try {
      await _dio.delete('/library/$docId');
      await loadPersonalDocs(userId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

// Provider
final libraryProvider = NotifierProvider<LibraryNotifier, LibraryState>(LibraryNotifier.new);
