import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

/// Goal type: REVENUE or DEALS_CLOSED
enum GoalType {
  revenue('REVENUE', 'Revenue'),
  dealsClosed('DEALS_CLOSED', 'Deals Closed');

  final String value;
  final String label;
  const GoalType(this.value, this.label);

  static GoalType fromString(String? val) {
    if (val == null) return GoalType.revenue;
    return GoalType.values.firstWhere(
      (e) => e.value.toUpperCase() == val.toUpperCase(),
      orElse: () => GoalType.revenue,
    );
  }
}

/// Period type: MONTHLY, QUARTERLY, YEARLY, CUSTOM
enum PeriodType {
  monthly('MONTHLY', 'Monthly'),
  quarterly('QUARTERLY', 'Quarterly'),
  yearly('YEARLY', 'Yearly'),
  custom('CUSTOM', 'Custom');

  final String value;
  final String label;
  const PeriodType(this.value, this.label);

  static PeriodType fromString(String? val) {
    if (val == null) return PeriodType.monthly;
    return PeriodType.values.firstWhere(
      (e) => e.value.toUpperCase() == val.toUpperCase(),
      orElse: () => PeriodType.monthly,
    );
  }
}

/// Goal status: on_track, at_risk, behind, completed
enum GoalStatus {
  onTrack('on_track', 'On Track', AppColors.success500, AppColors.success50),
  atRisk('at_risk', 'At Risk', AppColors.warning500, AppColors.warning50),
  behind('behind', 'Behind', AppColors.danger500, AppColors.danger50),
  completed('completed', 'Completed', AppColors.primary500, AppColors.primary50);

  final String value;
  final String label;
  final Color color;
  final Color bgColor;
  const GoalStatus(this.value, this.label, this.color, this.bgColor);

  static GoalStatus fromString(String? val) {
    if (val == null) return GoalStatus.behind;
    final normalized = val.toLowerCase().replaceAll(' ', '_');
    return GoalStatus.values.firstWhere(
      (e) => e.value == normalized,
      orElse: () => GoalStatus.behind,
    );
  }
}

/// Sales Goal Assignee Reference
class GoalAssignee {
  final String id;
  final String name;

  const GoalAssignee({required this.id, required this.name});

  factory GoalAssignee.fromJson(Map<String, dynamic> json) {
    final email = json['email'] as String? ?? '';
    final userDetails = json['user_details'] as Map<String, dynamic>?;
    final detailsName = userDetails != null ? userDetails['name'] as String? ?? '' : '';
    final detailsEmail = userDetails != null ? userDetails['email'] as String? ?? '' : '';
    
    String displayName = detailsName.isNotEmpty ? detailsName : (detailsEmail.isNotEmpty ? detailsEmail : email);
    if (displayName.isEmpty) displayName = 'Unknown User';

    return GoalAssignee(
      id: json['id']?.toString() ?? '',
      name: displayName,
    );
  }
}

/// Sales Goal Team Reference
class GoalTeam {
  final String id;
  final String name;

  const GoalTeam({required this.id, required this.name});

  factory GoalTeam.fromJson(Map<String, dynamic> json) {
    return GoalTeam(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Team',
    );
  }
}

/// Goal Model
class Goal {
  final String id;
  final String name;
  final GoalType goalType;
  final double targetValue;
  final PeriodType periodType;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final GoalAssignee? assignedTo;
  final String? assignedToId;
  final GoalTeam? team;
  final String? teamId;
  final bool isActive;
  final double progressValue;
  final double progressPercent;
  final GoalStatus status;
  final DateTime? createdAt;

  const Goal({
    required this.id,
    required this.name,
    required this.goalType,
    required this.targetValue,
    required this.periodType,
    this.periodStart,
    this.periodEnd,
    this.assignedTo,
    this.assignedToId,
    this.team,
    this.teamId,
    required this.isActive,
    required this.progressValue,
    required this.progressPercent,
    required this.status,
    this.createdAt,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? key) {
      if (key == null) return null;
      return DateTime.tryParse(key);
    }

    final assignedDetail = json['assigned_to_detail'] as Map<String, dynamic>?;
    final teamDetail = json['team_detail'] as Map<String, dynamic>?;

    return Goal(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? 'Untitled Goal',
      goalType: GoalType.fromString(json['goal_type'] as String?),
      targetValue: double.tryParse(json['target_value']?.toString() ?? '0') ?? 0.0,
      periodType: PeriodType.fromString(json['period_type'] as String?),
      periodStart: parseDate(json['period_start'] as String?),
      periodEnd: parseDate(json['period_end'] as String?),
      assignedTo: assignedDetail != null ? GoalAssignee.fromJson(assignedDetail) : null,
      assignedToId: json['assigned_to']?.toString(),
      team: teamDetail != null ? GoalTeam.fromJson(teamDetail) : null,
      teamId: json['team']?.toString(),
      isActive: json['is_active'] as bool? ?? true,
      progressValue: double.tryParse(json['progress_value']?.toString() ?? '0') ?? 0.0,
      progressPercent: double.tryParse(json['progress_percent']?.toString() ?? '0') ?? 0.0,
      status: GoalStatus.fromString(json['status'] as String?),
      createdAt: parseDate(json['created_at'] as String? ?? json['created_on'] as String?),
    );
  }
}

/// Leaderboard Entry
class LeaderboardEntry {
  final int rank;
  final String goalId;
  final String goalName;
  final String user;
  final double target;
  final double achieved;
  final double percent;

  const LeaderboardEntry({
    required this.rank,
    required this.goalId,
    required this.goalName,
    required this.user,
    required this.target,
    required this.achieved,
    required this.percent,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] as int? ?? 0,
      goalId: json['goal_id']?.toString() ?? '',
      goalName: json['goal_name']?.toString() ?? '',
      user: json['user']?.toString() ?? 'Unknown User',
      target: double.tryParse(json['target']?.toString() ?? '0') ?? 0.0,
      achieved: double.tryParse(json['achieved']?.toString() ?? '0') ?? 0.0,
      percent: double.tryParse(json['percent']?.toString() ?? '0') ?? 0.0,
    );
  }
}
