import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../config/api_config.dart';
import '../data/models/timesheet.dart';
import '../services/api_service.dart';

class TimesheetState {
  final TimesheetSummary? summary;
  final bool isLoading;
  final String? errorMessage;
  
  // Filters
  final DateTime startDate;
  final DateTime endDate;
  final String profileFilter;

  const TimesheetState({
    this.summary,
    required this.isLoading,
    this.errorMessage,
    required this.startDate,
    required this.endDate,
    required this.profileFilter,
  });

  TimesheetState copyWith({
    TimesheetSummary? summary,
    bool? isLoading,
    String? errorMessage,
    DateTime? startDate,
    DateTime? endDate,
    String? profileFilter,
  }) {
    return TimesheetState(
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      profileFilter: profileFilter ?? this.profileFilter,
    );
  }
}

class TimesheetNotifier extends Notifier<TimesheetState> {
  final ApiService _api = ApiService();

  @override
  TimesheetState build() {
    Future.microtask(() => load());
    return TimesheetState(
      isLoading: false,
      startDate: _getInitialStartDate(),
      endDate: _getInitialEndDate(),
      profileFilter: '',
    );
  }

  static DateTime _getInitialStartDate() {
    final now = DateTime.now();
    final dayOfWeek = now.weekday; // Mon = 1, Sun = 7
    return now.subtract(Duration(days: dayOfWeek - 1));
  }

  static DateTime _getInitialEndDate() {
    return _getInitialStartDate().add(const Duration(days: 6));
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final formatter = DateFormat('yyyy-MM-dd');
      final queryParams = {
        'start': formatter.format(state.startDate),
        'end': formatter.format(state.endDate),
      };

      if (state.profileFilter.isNotEmpty) {
        queryParams['profile'] = state.profileFilter;
      }

      final response = await _api.get(ApiConfig.timesheet, queryParams: queryParams);
      if (!response.success || response.data == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.message ?? 'Failed to load timesheet',
        );
        return;
      }

      state = state.copyWith(
        isLoading: false,
        summary: TimesheetSummary.fromJson(response.data!),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> setDateRange(DateTime start, DateTime end) async {
    state = state.copyWith(startDate: start, endDate: end);
    await load();
  }

  Future<void> setProfileFilter(String profileId) async {
    state = state.copyWith(profileFilter: profileId);
    await load();
  }

  Future<void> shiftWeek(int deltaDays) async {
    final newStart = state.startDate.add(Duration(days: deltaDays));
    final newEnd = state.endDate.add(Duration(days: deltaDays));
    state = state.copyWith(startDate: newStart, endDate: newEnd);
    await load();
  }

  /// Stop a running time entry by id
  Future<bool> stopTimer(String entryId) async {
    state = state.copyWith(isLoading: true);
    final response = await _api.post(ApiConfig.timeEntryStop(entryId), {});
    if (response.success) {
      await load();
      return true;
    } else {
      state = state.copyWith(isLoading: false, errorMessage: response.message);
      return false;
    }
  }
}

final timesheetProvider = NotifierProvider<TimesheetNotifier, TimesheetState>(
  TimesheetNotifier.new,
);
