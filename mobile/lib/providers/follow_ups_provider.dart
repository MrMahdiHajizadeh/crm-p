import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/api_config.dart';
import '../data/models/follow_up.dart';
import '../services/api_service.dart';

/// Follow-up groups: overdue, today, tomorrow, thisWeek, later
class FollowUpsState {
  final Map<String, List<FollowUp>> groups;
  final bool myOnly;
  final bool isLoading;
  final String? errorMessage;

  const FollowUpsState({
    required this.groups,
    required this.myOnly,
    this.isLoading = false,
    this.errorMessage,
  });

  FollowUpsState copyWith({
    Map<String, List<FollowUp>>? groups,
    bool? myOnly,
    bool? isLoading,
    String? errorMessage,
  }) {
    return FollowUpsState(
      groups: groups ?? this.groups,
      myOnly: myOnly ?? this.myOnly,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class FollowUpsNotifier extends Notifier<FollowUpsState> {
  final ApiService _api = ApiService();

  @override
  FollowUpsState build() {
    Future.microtask(() => load());
    return const FollowUpsState(
      groups: {
        'overdue': [],
        'today': [],
        'tomorrow': [],
        'thisWeek': [],
        'later': [],
      },
      myOnly: false,
    );
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final queryParams = <String, String>{};
      if (state.myOnly) {
        queryParams['my_only'] = 'true';
      }

      final response = await _api.get(ApiConfig.followUps, queryParams: queryParams);
      if (!response.success || response.data == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.message ?? 'Failed to load follow-ups',
        );
        return;
      }

      final data = response.data!;
      
      List<FollowUp> parseList(dynamic listJson) {
        if (listJson is! List) return [];
        return listJson.map((e) => FollowUp.fromJson(e as Map<String, dynamic>)).toList();
      }

      final groups = {
        'overdue': parseList(data['overdue']),
        'today': parseList(data['today']),
        'tomorrow': parseList(data['tomorrow']),
        'thisWeek': parseList(data['this_week']),
        'later': parseList(data['later']),
      };

      state = state.copyWith(
        isLoading: false,
        groups: groups,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> toggleMyOnly() async {
    state = state.copyWith(myOnly: !state.myOnly);
    await load();
  }

  /// Create an interaction (log follow-up activity) and optionally mark a previous follow-up completed
  Future<bool> createInteraction({
    required String entityType,
    required String entityId,
    required String interactionType,
    required String subject,
    required String description,
    required String interactionDate,
    int? durationMinutes,
    String? result,
    String? followUpDate,
    String? completedInteractionId,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final payload = <String, dynamic>{
        'entity_type': entityType,
        'entity_id': entityId,
        'interaction_type': interactionType,
        'interaction_date': interactionDate,
        'subject': subject,
        'description': description,
      };

      if (durationMinutes != null) payload['duration_minutes'] = durationMinutes;
      if (result != null && result.isNotEmpty) payload['result'] = result;
      if (followUpDate != null && followUpDate.isNotEmpty) payload['follow_up_date'] = followUpDate;

      final response = await _api.post(ApiConfig.interactions, payload);
      if (!response.success) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.message ?? 'Failed to log interaction',
        );
        return false;
      }

      // If we are completing a previous follow-up, clear its follow-up date
      if (completedInteractionId != null && completedInteractionId.isNotEmpty) {
        final patchUrl = '${ApiConfig.interactions}$completedInteractionId/';
        await _api.patch(patchUrl, {'follow_up_date': null});
      }

      await load();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }
}

final followUpsProvider = NotifierProvider<FollowUpsNotifier, FollowUpsState>(
  FollowUpsNotifier.new,
);
