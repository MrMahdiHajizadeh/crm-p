/// Timesheet Entry Model representing an individual time log
class TimesheetEntry {
  final String id;
  final String? description;
  final int durationMinutes;
  final String? caseId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final bool billable;
  final String? invoiceId;
  final bool autoStopped;
  final bool isRunning;

  const TimesheetEntry({
    required this.id,
    this.description,
    required this.durationMinutes,
    this.caseId,
    required this.startedAt,
    this.endedAt,
    required this.billable,
    this.invoiceId,
    required this.autoStopped,
    required this.isRunning,
  });

  factory TimesheetEntry.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(String val) {
      return DateTime.parse(val);
    }
    
    DateTime? parseNullableDate(String? val) {
      if (val == null) return null;
      return DateTime.tryParse(val);
    }

    final startedAtStr = json['started_at'] as String? ?? '';
    final endedAtStr = json['ended_at'] as String?;

    return TimesheetEntry(
      id: json['id']?.toString() ?? '',
      description: json['description'] as String?,
      durationMinutes: json['duration_minutes'] as int? ?? 0,
      caseId: json['case']?.toString() ?? json['case_id']?.toString(),
      startedAt: startedAtStr.isNotEmpty ? parseDate(startedAtStr) : DateTime.now(),
      endedAt: parseNullableDate(endedAtStr),
      billable: json['billable'] as bool? ?? false,
      invoiceId: json['invoice']?.toString(),
      autoStopped: json['auto_stopped'] as bool? ?? false,
      isRunning: json['is_running'] as bool? ?? (endedAtStr == null),
    );
  }
}

/// Timesheet Day Summary containing the date and list of entries for that day
class TimesheetDay {
  final String date;
  final int totalMinutes;
  final List<TimesheetEntry> entries;

  const TimesheetDay({
    required this.date,
    required this.totalMinutes,
    required this.entries,
  });

  factory TimesheetDay.fromJson(Map<String, dynamic> json) {
    final entryList = json['entries'] as List<dynamic>? ?? [];
    return TimesheetDay(
      date: json['date'] as String? ?? '',
      totalMinutes: json['total_minutes'] as int? ?? 0,
      entries: entryList.map((e) => TimesheetEntry.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

/// Overall Timesheet summary containing all days and aggregation metrics
class TimesheetSummary {
  final List<TimesheetDay> days;
  final int totalMinutes;
  final int billableMinutes;
  final int runningCount;
  final DateTime serverNow;

  const TimesheetSummary({
    required this.days,
    required this.totalMinutes,
    required this.billableMinutes,
    required this.runningCount,
    required this.serverNow,
  });

  factory TimesheetSummary.fromJson(Map<String, dynamic> json) {
    final dayList = json['days'] as List<dynamic>? ?? [];
    final serverNowStr = json['server_now'] as String? ?? '';
    
    return TimesheetSummary(
      days: dayList.map((d) => TimesheetDay.fromJson(d as Map<String, dynamic>)).toList(),
      totalMinutes: json['total_minutes'] as int? ?? 0,
      billableMinutes: json['billable_minutes'] as int? ?? 0,
      runningCount: json['running_count'] as int? ?? 0,
      serverNow: serverNowStr.isNotEmpty ? DateTime.parse(serverNowStr) : DateTime.now(),
    );
  }
}
