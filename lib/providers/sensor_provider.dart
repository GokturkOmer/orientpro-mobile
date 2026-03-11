import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../../models/sensor.dart';

final _dio = Dio(BaseOptions(baseUrl: ApiConfig.webUrl, connectTimeout: const Duration(seconds: 5)));

// --- Latest sensor values (auto-refresh) ---
final sensorLatestProvider = NotifierProvider<SensorLatestNotifier, AsyncValue<List<SensorLatestValue>>>(SensorLatestNotifier.new);

class SensorLatestNotifier extends Notifier<AsyncValue<List<SensorLatestValue>>> {
  Timer? _timer;

  @override
  AsyncValue<List<SensorLatestValue>> build() {
    ref.onDispose(() => _timer?.cancel());
    fetch();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => fetch());
    return const AsyncValue.loading();
  }

  Future<void> fetch() async {
    try {
      final res = await _dio.get('/sensors/readings/latest');
      final list = (res.data as List).map((e) => SensorLatestValue.fromJson(e)).toList();
      state = AsyncValue.data(list);
    } catch (e) {
      if (state is! AsyncData) {
        state = AsyncValue.error(e, StackTrace.current);
      }
    }
  }
}

// --- Alarm stats ---
final alarmStatsProvider = NotifierProvider<AlarmStatsNotifier, AsyncValue<AlarmStats>>(AlarmStatsNotifier.new);

class AlarmStatsNotifier extends Notifier<AsyncValue<AlarmStats>> {
  Timer? _timer;

  @override
  AsyncValue<AlarmStats> build() {
    ref.onDispose(() => _timer?.cancel());
    fetch();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => fetch());
    return const AsyncValue.loading();
  }

  Future<void> fetch() async {
    try {
      final res = await _dio.get('/alarms/stats');
      state = AsyncValue.data(AlarmStats.fromJson(res.data));
    } catch (e) {
      if (state is! AsyncData) {
        state = AsyncValue.error(e, StackTrace.current);
      }
    }
  }
}

// --- Reading count ---
final readingCountProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await _dio.get('/sensors/readings/count');
  return res.data;
});

// --- Sensor readings history (for charts) ---
final sensorReadingsProvider = FutureProvider.family<List<SensorReading>, int>((ref, sensorId) async {
  final res = await _dio.get('/sensors/$sensorId/readings', queryParameters: {'hours': 1, 'limit': 200});
  return (res.data as List).map((e) => SensorReading.fromJson(e)).toList();
});

// --- Active alarms ---
final activeAlarmsProvider = NotifierProvider<ActiveAlarmsNotifier, AsyncValue<List<AlarmEvent>>>(ActiveAlarmsNotifier.new);

class ActiveAlarmsNotifier extends Notifier<AsyncValue<List<AlarmEvent>>> {
  Timer? _timer;

  @override
  AsyncValue<List<AlarmEvent>> build() {
    ref.onDispose(() => _timer?.cancel());
    fetch();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => fetch());
    return const AsyncValue.loading();
  }

  Future<void> fetch() async {
    try {
      final res = await _dio.get('/alarms/', queryParameters: {'limit': 50});
      final list = (res.data as List).map((e) => AlarmEvent.fromJson(e)).toList();
      state = AsyncValue.data(list);
    } catch (e) {
      if (state is! AsyncData) {
        state = AsyncValue.error(e, StackTrace.current);
      }
    }
  }

  Future<void> acknowledge(int alarmId, String userId) async {
    await _dio.put('/alarms/$alarmId/acknowledge', data: {'user_id': userId});
    fetch();
  }
}

// --- All sensor definitions ---
final sensorListProvider = FutureProvider<List<SensorDefinition>>((ref) async {
  final res = await _dio.get('/sensors/');
  return (res.data as List).map((e) => SensorDefinition.fromJson(e)).toList();
});
