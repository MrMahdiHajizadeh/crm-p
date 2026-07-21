import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../core/theme/theme.dart';

/// Follow-up Interaction Type
enum FollowUpType {
  call('call', 'Call', LucideIcons.phone),
  email('email', 'Email', LucideIcons.mail),
  meeting('meeting', 'Meeting', LucideIcons.users),
  note('note', 'Note', LucideIcons.file_text);

  final String value;
  final String label;
  final IconData icon;
  const FollowUpType(this.value, this.label, this.icon);

  static FollowUpType fromString(String? val) {
    if (val == null) return FollowUpType.call;
    return FollowUpType.values.firstWhere(
      (e) => e.value.toLowerCase() == val.toLowerCase(),
      orElse: () => FollowUpType.call,
    );
  }
}

/// Follow-up model matching the interactions structure from backend
class FollowUp {
  final String id;
  final String entityType;
  final String entityId;
  final String entityName;
  final String? subject;
  final FollowUpType interactionType;
  final int? durationMinutes;
  final DateTime? followUpDate;
  final String? description;
  final DateTime? interactionDate;
  final String? result;

  const FollowUp({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.entityName,
    this.subject,
    required this.interactionType,
    this.durationMinutes,
    this.followUpDate,
    this.description,
    this.interactionDate,
    this.result,
  });

  factory FollowUp.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? key) {
      if (key == null) return null;
      return DateTime.tryParse(key);
    }

    return FollowUp(
      id: json['id']?.toString() ?? '',
      entityType: json['entity_type'] as String? ?? 'Lead',
      entityId: json['entity_id']?.toString() ?? '',
      entityName: json['entity_name'] as String? ?? '',
      subject: json['subject'] as String?,
      interactionType: FollowUpType.fromString(json['interaction_type'] as String?),
      durationMinutes: json['duration_minutes'] as int?,
      followUpDate: parseDate(json['follow_up_date'] as String?),
      description: json['description'] as String?,
      interactionDate: parseDate(json['interaction_date'] as String?),
      result: json['result'] as String?,
    );
  }

  IconData get entityIcon {
    switch (entityType.toLowerCase()) {
      case 'lead':
        return LucideIcons.target;
      case 'contact':
        return LucideIcons.user;
      case 'account':
        return LucideIcons.building_2;
      case 'opportunity':
        return LucideIcons.sparkles;
      default:
        return LucideIcons.target;
    }
  }

  String get routePath {
    switch (entityType.toLowerCase()) {
      case 'lead':
        return '/leads/$entityId';
      case 'contact':
        return '/contacts/$entityId';
      case 'account':
        return '/accounts/$entityId';
      case 'opportunity':
        return '/deals/$entityId';
      default:
        return '/dashboard';
    }
  }
}
