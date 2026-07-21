import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/api_config.dart';
import '../data/models/goal.dart';
import '../services/api_service.dart';

class GoalsState {
  final List<Goal> goals;
  final List<LeaderboardEntry> leaderboard;
  final bool isLoading;
  final String? errorMessage;
  
  // Filters
  final String search;
  final String status; // 'all', 'on_track', 'at_risk', 'behind', 'completed'
  final String assignedToId;
  final String teamId;
  final String periodType;
  final String leaderboardPeriod; // 'MONTHLY', 'QUARTERLY', 'YEARLY'
  
  // Pagination
  final int page;
  final int limit;
  final int totalCount;

  const GoalsState({
    required this.goals,
    required this.leaderboard,
    required this.isLoading,
    this.errorMessage,
    required this.search,
    required this.status,
    required this.assignedToId,
    required this.teamId,
    required this.periodType,
    required this.leaderboardPeriod,
    required this.page,
    required this.limit,
    required this.totalCount,
  });

  GoalsState copyWith({
    List<Goal>? goals,
    List<LeaderboardEntry>? leaderboard,
    bool? isLoading,
    String? errorMessage,
    String? search,
    String? status,
    String? assignedToId,
    String? teamId,
    String? periodType,
    String? leaderboardPeriod,
    int? page,
    int? limit,
    int? totalCount,
  }) {
    return GoalsState(
      goals: goals ?? this.goals,
      leaderboard: leaderboard ?? this.leaderboard,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      search: search ?? this.search,
      status: status ?? this.status,
      assignedToId: assignedToId ?? this.assignedToId,
      teamId: teamId ?? this.teamId,
      periodType: periodType ?? this.periodType,
      leaderboardPeriod: leaderboardPeriod ?? this.leaderboardPeriod,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

class GoalsNotifier extends Notifier<GoalsState> {
  final ApiService _api = ApiService();

  @override
  GoalsState build() {
    Future.microtask(() => load());
    return const GoalsState(
      goals: [],
      leaderboard: [],
      isLoading: false,
      search: '',
      status: 'all',
      assignedToId: '',
      teamId: '',
      periodType: '',
      leaderboardPeriod: 'MONTHLY',
      page: 1,
      limit: 10,
      totalCount: 0,
    );
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final queryParams = <String, String>{
        'limit': state.limit.toString(),
        'offset': ((state.page - 1) * state.limit).toString(),
      };

      if (state.search.isNotEmpty) queryParams['search'] = state.search;
      if (state.assignedToId.isNotEmpty) queryParams['assigned_to'] = state.assignedToId;
      if (state.teamId.isNotEmpty) queryParams['team'] = state.teamId;
      if (state.periodType.isNotEmpty) queryParams['period_type'] = state.periodType;

      if (state.status == 'active' || state.status == 'completed' || state.status == 'on_track') {
        queryParams['active'] = 'true';
      }

      final goalsResponse = await _api.get(ApiConfig.goals, queryParams: queryParams);
      if (!goalsResponse.success || goalsResponse.data == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: goalsResponse.message ?? 'Failed to load goals',
        );
        return;
      }

      // Fetch leaderboard
      final leaderboardParams = {'period_type': state.leaderboardPeriod};
      final leaderboardResponse = await _api.get(ApiConfig.goalsLeaderboard, queryParams: leaderboardParams);

      final goalsData = goalsResponse.data!;
      final goalsListJson = goalsData['goals'] as List<dynamic>? ?? [];
      final goalsList = goalsListJson.map((e) => Goal.fromJson(e as Map<String, dynamic>)).toList();
      final total = goalsData['goals_count'] as int? ?? goalsList.length;

      // Filter status client side if needed, matching SvelteKit logic
      List<Goal> filteredGoals = goalsList;
      if (state.status != 'all') {
        filteredGoals = goalsList.where((goal) {
          if (state.status == 'completed') {
            return goal.status == GoalStatus.completed;
          } else if (state.status == 'on_track') {
            return goal.status == GoalStatus.onTrack;
          } else if (state.status == 'at_risk') {
            return goal.status == GoalStatus.atRisk;
          } else if (state.status == 'behind') {
            return goal.status == GoalStatus.behind;
          }
          return true;
        }).toList();
      }

      List<LeaderboardEntry> leaderboardList = [];
      if (leaderboardResponse.success && leaderboardResponse.data != null) {
        final lbData = leaderboardResponse.data!['leaderboard'] as List<dynamic>? ?? [];
        leaderboardList = lbData.map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>)).toList();
      }

      state = state.copyWith(
        isLoading: false,
        goals: filteredGoals,
        leaderboard: leaderboardList,
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
    String? search,
    String? status,
    String? assignedToId,
    String? teamId,
    String? periodType,
    int? page,
  }) async {
    state = state.copyWith(
      search: search ?? state.search,
      status: status ?? state.status,
      assignedToId: assignedToId ?? state.assignedToId,
      teamId: teamId ?? state.teamId,
      periodType: periodType ?? state.periodType,
      page: page ?? 1,
    );
    await load();
  }

  Future<void> setLeaderboardPeriod(String period) async {
    state = state.copyWith(leaderboardPeriod: period);
    await load();
  }

  Future<bool> createGoal(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true);
    final response = await _api.post(ApiConfig.goals, data);
    if (response.success) {
      await load();
      return true;
    } else {
      state = state.copyWith(isLoading: false, errorMessage: response.message);
      return false;
    }
  }

  Future<bool> updateGoal(String id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true);
    final response = await _api.put('${ApiConfig.goals}$id/', data);
    if (response.success) {
      await load();
      return true;
    } else {
      state = state.copyWith(isLoading: false, errorMessage: response.message);
      return false;
    }
  }

  Future<bool> deleteGoal(String id) async {
    state = state.copyWith(isLoading: true);
    final response = await _api.delete('${ApiConfig.goals}$id/');
    if (response.success) {
      await load();
      return true;
    } else {
      state = state.copyWith(isLoading: false, errorMessage: response.message);
      return false;
    }
  }
}

final goalsProvider = NotifierProvider<GoalsNotifier, GoalsState>(
  GoalsNotifier.new,
);
