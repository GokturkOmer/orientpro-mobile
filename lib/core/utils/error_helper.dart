import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';

class ErrorHelper {
  /// DioException, SocketException, TimeoutException gibi hatalari
  /// kullanıcı dostu Turkce mesaja cevirir.
  /// Backend'den gelen 'detail' alanini oncelikli kullanir.
  static String getMessage(Object error) {
    if (error is DioException) {
      final detail = error.response?.data;
      if (detail is Map && detail['detail'] != null) {
        return detail['detail'].toString();
      }

      switch (error.response?.statusCode) {
        case 400:
          return 'Gecersiz istek';
        case 403:
          return 'Bu işlem icin yetkiniz yok';
        case 404:
          return 'Istenen kayıt bulunamadi';
        case 409:
          return 'Bu kayıt zaten mevcut';
        case 422:
          return 'Girilen bilgiler hatali';
        case 500:
          return 'Sunucu hatasi, lütfen tekrar deneyin';
      }

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Baglanti zaman asimina ugradi';
        case DioExceptionType.connectionError:
          return 'Sunucuya baglanilamadi';
        default:
          return 'Baglanti hatasi';
      }
    }

    if (error is SocketException) {
      return 'Internet baglantisi bulunamadi';
    }

    if (error is TimeoutException) {
      return 'Baglanti zaman asimina ugradi';
    }

    return 'Beklenmeyen bir hata olustu';
  }
}
