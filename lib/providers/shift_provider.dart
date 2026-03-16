import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/shift.dart';
import '../core/network/auth_dio.dart';
import '../core/utils/error_helper.dart';

class ShiftState {
  final List<Shift> shifts;
  final List<Task> tasks;
  final bool isLoading;
  final String? error;

  ShiftState({this.shifts = const [], this.tasks = const [], this.isLoading = false, this.error});

  ShiftState copyWith({List<Shift>? shifts, List<Task>? tasks, bool? isLoading, String? error}) {
    return ShiftState(
      shifts: shifts ?? this.shifts,
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ShiftNotifier extends Notifier<ShiftState> {
  Dio get _dio => ref.read(authDioProvider);

  @override
  ShiftState build() {
    return ShiftState();
  }

  Future<void> loadShifts(String userId, {String? startDate, String? endDate}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final params = <String, dynamic>{'user_id': userId};
      if (startDate != null) params['start_date'] = startDate;
      if (endDate != null) params['end_date'] = endDate;
      final resp = await _dio.get('/shifts/', queryParameters: params);
      final items = (resp.data as List).map((j) => Shift.fromJson(j)).toList();
      state = state.copyWith(shifts: items, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorHelper.getMessage(e));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorHelper.getMessage(e));
    }
  }

  Future<void> loadTasks(String userId, {String? status, String? dueDate}) async {
    try {
      final params = <String, dynamic>{'assigned_to': userId};
      if (status != null) params['status'] = status;
      if (dueDate != null) params['due_date'] = dueDate;
      final resp = await _dio.get('/shifts/tasks', queryParameters: params);
      final items = (resp.data as List).map((j) => Task.fromJson(j)).toList();
      state = state.copyWith(tasks: items);
    } on DioException catch (e) {
      state = state.copyWith(error: ErrorHelper.getMessage(e));
    } catch (e) {
      state = state.copyWith(error: ErrorHelper.getMessage(e));
    }
  }

  Future<bool> updateTaskStatus(String taskId, String status, {String? notes}) async {
    try {
      final data = <String, dynamic>{'status': status};
      if (notes != null) data['completion_notes'] = notes;
      await _dio.patch('/shifts/tasks/$taskId', data: data);
      // Refresh tasks
      final currentTasks = state.tasks;
      final updated = currentTasks.map((t) {
        if (t.id == taskId) {
          return Task.fromJson({
            ...{
              'id': t.id, 'title': t.title, 'description': t.description,
              'assigned_to': t.assignedTo, 'created_by': t.createdBy,
              'due_date': t.dueDate, 'priority': t.priority,
              'status': status, 'category': t.category,
              'department': t.department, 'completed_at': t.completedAt,
              'completion_notes': notes ?? t.completionNotes,
              'created_at': t.createdAt, 'assigned_name': t.assignedName,
            },
          });
        }
        return t;
      }).toList();
      state = state.copyWith(tasks: updated);
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

final shiftProvider = NotifierProvider<ShiftNotifier, ShiftState>(ShiftNotifier.new);
