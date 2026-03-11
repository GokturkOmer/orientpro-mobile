import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/config/api_config.dart';

final predictionProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = Dio(BaseOptions(baseUrl: ApiConfig.webUrl));
  final res = await dio.get('/predictions/health-scores');
  return res.data;
});
