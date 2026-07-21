import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../config/api_config.dart';
import '../data/models/supervision_activity.dart';
import '../services/api_service.dart';

class SupervisionState {
  final List<SupervisionActivity> activities;
  final bool isLoading;
  final String? errorMessage;

  // Filters
  final String entityType;
  final String action;
  final String userId;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  // Pagination
  final int offset;
  final int limit;
  final int totalCount;

  const SupervisionState({
    required this.activities,
    required this.isLoading,
    this.errorMessage,
    required this.entityType,
    required this.action,
    required this.userId,
    this.dateFrom,
    this.dateTo,
    required this.offset,
    required this.limit,
    required this.totalCount,
  });

  SupervisionState copyWith({
    List<SupervisionActivity>? activities,
    bool? isLoading,
    String? errorMessage,
    String? entityType,
    String? action,
    String? userId,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? offset,
    int? limit,
    int? totalCount,
  }) {
    return SupervisionState(
      activities: activities ?? this.activities,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      entityType: entityType ?? this.entityType,
      action: action ?? this.action,
      userId: userId ?? this.userId,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      offset: offset ?? this.offset,
      limit: limit ?? this.limit,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

class SupervisionNotifier extends Notifier<SupervisionState> {
  final ApiService _api = ApiService();

  @override
  SupervisionState build() {
    // Schedule load after the build phase completes
    Future.microtask(() => load());
    return const SupervisionState(
      activities: [],
      isLoading: false,
      entityType: '',
      action: '',
      userId: '',
      offset: 0,
      limit: 50,
      totalCount: 0,
    );
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final queryParams = <String, String>{
        'limit': state.limit.toString(),
        'offset': state.offset.toString(),
      };

      if (state.entityType.isNotEmpty) queryParams['entity_type'] = state.entityType;
      if (state.action.isNotEmpty) queryParams['action'] = state.action;
      if (state.userId.isNotEmpty) queryParams['user_id'] = state.userId;

      final formatter = DateFormat('yyyy-MM-dd');
      if (state.dateFrom != null) {
        queryParams['date_from'] = formatter.format(state.dateFrom!);
      }
      if (state.dateTo != null) {
        queryParams['date_to'] = formatter.format(state.dateTo!);
      }

      final response = await _api.get(ApiConfig.activities, queryParams: queryParams);
      if (!response.success || response.data == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.message ?? 'Failed to load supervision activities',
        );
        return;
      }

      final data = response.data!;
      final activityListJson = data['activities'] as List<dynamic>? ?? [];
      final activityList = activityListJson.map((e) => SupervisionActivity.fromJson(e as Map<String, dynamic>)).toList();
      final total = data['total_count'] as int? ?? activityList.length;

      state = state.copyWith(
        isLoading: false,
        activities: activityList,
        totalCount: total,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> setFilters({
    String? entityType,
    String? action,
    String? userId,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    state = state.copyWith(
      entityType: entityType ?? state.entityType,
      action: action ?? state.action,
      userId: userId ?? state.userId,
      dateFrom: dateFrom,
      dateTo: dateTo,
      offset: 0,
    );
    await load();
  }

  Future<void> nextPage() async {
    if (state.offset + state.limit < state.totalCount) {
      state = state.copyWith(offset: state.offset + state.limit);
      await load();
    }
  }

  Future<void> prevPage() async {
    if (state.offset - state.limit >= 0) {
      state = state.copyWith(offset: state.offset - state.limit);
      await load();
    }
  }
}

final supervisionProvider = NotifierProvider<SupervisionNotifier, SupervisionState>(
  SupervisionNotifier.new,
);
