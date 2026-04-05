import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/network/auth_dio.dart';
import '../core/utils/error_helper.dart';

// ── Model ──

class ShiftScheduleModel {
  final String id;
  final String organizationId;
  final String shiftType;
  final String startTime;
  final String endTime;
  final String break1Time;
  final String break2Time;
  final String break3Time;
  final bool isActive;

  ShiftScheduleModel({
    required this.id,
    required this.organizationId,
    required this.shiftType,
    required this.startTime,
    required this.endTime,
    required this.break1Time,
    required this.break2Time,
    required this.break3Time,
    this.isActive = true,
  });

  factory ShiftScheduleModel.fromJson(Map<String, dynamic> json) {
    return ShiftScheduleModel(
      id: json['id'] ?? '',
      organizationId: json['organization_id'] ?? '',
      shiftType: json['shift_type'] ?? '',
      startTime: json['start_time'] ?? '08:00:00',
      endTime: json['end_time'] ?? '16:00:00',
      break1Time: json['break_1_time'] ?? '10:00:00',
      break2Time: json['break_2_time'] ?? '12:00:00',
      break3Time: json['break_3_time'] ?? '14:00:00',
      isActive: json['is_active'] ?? true,
    );
  }
}

// ── State ──

class ShiftScheduleState {
  final List<ShiftScheduleModel> shifts;
  final bool isLoading;
  final String? savingShiftId;
  final String? error;
  final String? successMessage;

  const ShiftScheduleState({
    this.shifts = const [],
    this.isLoading = false,
    this.savingShiftId,
    this.error,
    this.successMessage,
  });

  bool get isSaving => savingShiftId != null;

  ShiftScheduleState copyWith({
    List<ShiftScheduleModel>? shifts,
    bool? isLoading,
    String? savingShiftId,
    bool clearSaving = false,
    String? error,
    String? successMessage,
  }) {
    return ShiftScheduleState(
      shifts: shifts ?? this.shifts,
      isLoading: isLoading ?? this.isLoading,
      savingShiftId: clearSaving ? null : (savingShiftId ?? this.savingShiftId),
      error: error,
      successMessage: successMessage,
    );
  }
}

// ── Notifier ──

class ShiftScheduleNotifier extends Notifier<ShiftScheduleState> {
  Dio get _dio => ref.read(authDioProvider);

  @override
  ShiftScheduleState build() => const ShiftScheduleState();

  Future<void> loadShifts() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final resp = await _dio.get('/shift-schedules');
      final items = (resp.data as List)
          .map((j) => ShiftScheduleModel.fromJson(j as Map<String, dynamic>))
          .toList();
      state = state.copyWith(shifts: items, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorHelper.getMessage(e));
    }
  }

  Future<bool> updateShift(String id, Map<String, String> data) async {
    state = state.copyWith(savingShiftId: id, error: null, successMessage: null);
    try {
      await _dio.put('/shift-schedules/$id', data: data);
      await loadShifts();
      state = state.copyWith(clearSaving: true, successMessage: 'Vardiya güncellendi');
      return true;
    } on DioException catch (e) {
      state = state.copyWith(clearSaving: true, error: ErrorHelper.getMessage(e));
      return false;
    }
  }
}

final shiftScheduleProvider =
    NotifierProvider<ShiftScheduleNotifier, ShiftScheduleState>(ShiftScheduleNotifier.new);
