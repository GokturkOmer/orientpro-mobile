import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/auth_dio.dart';

final predictionProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.read(authDioProvider);
  final res = await dio.get('/predictions/health-scores');
  return res.data;
});
