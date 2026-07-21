import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../core/theme/theme.dart';

/// Supervision Activity model representing a change log entry across the organization
class SupervisionActivity {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String action;
  final String actionDisplay;
  final String entityType;
  final String entityId;
  final String entityName;
  final String description;
  final DateTime timestamp;
  final String? humanizedTime;

  const SupervisionActivity({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.action,
    required this.actionDisplay,
    required this.entityType,
    required this.entityId,
    required this.entityName,
    required this.description,
    required this.timestamp,
    this.humanizedTime,
  });

  factory SupervisionActivity.fromJson(Map<String, dynamic> json) {
    final userMap = json['user'] as Map<String, dynamic>? ?? {};
    final userDetails = userMap['user_details'] as Map<String, dynamic>? ?? {};
    
    final email = userMap['email'] as String? ?? '';
    final detailsEmail = userDetails['email'] as String? ?? '';
    final finalEmail = detailsEmail.isNotEmpty ? detailsEmail : email;
    
    final detailsName = userDetails['name'] as String? ?? '';
    final finalName = detailsName.isNotEmpty ? detailsName : (finalEmail.isNotEmpty ? finalEmail.split('@').first : 'Unknown');

    final actionVal = json['action'] as String? ?? '';
    final actionDisp = json['action_display'] as String? ?? actionVal;
    
    final entType = json['entity_type'] as String? ?? '';
    final entName = json['entity_name'] as String? ?? '';
    
    final desc = json['description'] as String? ?? 
        '${actionDisp.toUpperCase()} $entType: $entName';

    final timestampStr = json['timestamp'] as String? ?? '';

    return SupervisionActivity(
      id: json['id']?.toString() ?? '',
      userId: userMap['id']?.toString() ?? '',
      userName: finalName,
      userEmail: finalEmail,
      action: actionVal,
      actionDisplay: actionDisp,
      entityType: entType,
      entityId: json['entity_id']?.toString() ?? '',
      entityName: entName,
      description: desc,
      timestamp: timestampStr.isNotEmpty ? DateTime.parse(timestampStr) : DateTime.now(),
      humanizedTime: json['humanized_time'] as String?,
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
      case 'case':
      case 'ticket':
        return LucideIcons.briefcase;
      case 'task':
        return LucideIcons.square_check;
      case 'invoice':
        return LucideIcons.file_text;
      case 'event':
        return LucideIcons.calendar;
      case 'document':
        return LucideIcons.file;
      case 'team':
        return LucideIcons.users;
      default:
        return LucideIcons.activity;
    }
  }

  Color get actionColor {
    switch (action.toUpperCase()) {
      case 'CREATE':
        return AppColors.success600;
      case 'UPDATE':
        return AppColors.primary600;
      case 'DELETE':
        return AppColors.danger600;
      case 'ASSIGN':
        return AppColors.warning600;
      case 'STATUS_CHANGED':
        return Colors.indigo;
      case 'PRIORITY_CHANGED':
        return Colors.orange;
      case 'APPROVED':
        return AppColors.success500;
      case 'REJECTED':
        return AppColors.danger500;
      default:
        return AppColors.textSecondary;
    }
  }
}
