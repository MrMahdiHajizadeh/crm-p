import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'comment.dart';
import 'attachment.dart';
import 'lookup_models.dart';

/// Industry choices matching backend INDCHOICES
enum AccountIndustry {
  none('', 'None'),
  advertising('ADVERTISING', 'Advertising'),
  agriculture('AGRICULTURE', 'Agriculture'),
  apparel('APPAREL', 'Apparel'),
  banking('BANKING', 'Banking'),
  biotechnology('BIOTECHNOLOGY', 'Biotechnology'),
  chemicals('CHEMICALS', 'Chemicals'),
  communications('COMMUNICATIONS', 'Communications'),
  construction('CONSTRUCTION', 'Construction'),
  consulting('CONSULTING', 'Consulting'),
  education('EDUCATION', 'Education'),
  electronics('ELECTRONICS', 'Electronics'),
  energy('ENERGY', 'Energy'),
  engineering('ENGINEERING', 'Engineering'),
  entertainment('ENTERTAINMENT', 'Entertainment'),
  environmental('ENVIRONMENTAL', 'Environmental'),
  finance('FINANCE', 'Finance'),
  foodBeverage('FOOD & BEVERAGES', 'Food & Beverage'),
  government('GOVERNMENT', 'Government'),
  healthcare('HEALTHCARE', 'Healthcare'),
  hospitality('HOSPITALITY', 'Hospitality'),
  insurance('INSURANCE', 'Insurance'),
  machinery('MACHINERY', 'Machinery'),
  manufacturing('MANUFACTURING', 'Manufacturing'),
  media('MEDIA', 'Media'),
  notForProfit('NOT FOR PROFIT', 'Not for Profit'),
  other('OTHER', 'Other'),
  recreation('RECREATION', 'Recreation'),
  retail('RETAIL', 'Retail'),
  shipping('SHIPPING', 'Shipping'),
  technology('TECHNOLOGY', 'Technology'),
  telecommunications('TELECOMMUNICATIONS', 'Telecommunications'),
  transportation('TRANSPORTATION', 'Transportation'),
  utilities('UTILITIES', 'Utilities');

  final String value;
  final String label;
  const AccountIndustry(this.value, this.label);

  static AccountIndustry fromString(String? value) {
    if (value == null || value.isEmpty) return AccountIndustry.none;
    return AccountIndustry.values.firstWhere(
      (e) => e.value == value.toUpperCase(),
      orElse: () => AccountIndustry.other,
    );
  }
}

/// Account model for BottleCRM
class Account {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? website;
  final AccountIndustry industry;
  final int? numberOfEmployees;
  final double? annualRevenue;
  final String? currency;
  final String? addressLine;
  final String? city;
  final String? state;
  final String? postcode;
  final String? country;
  final String? description;
  final List<Map<String, dynamic>> assignedTo;
  final List<String> assignedToIds;
  final List<String> tags;
  final List<String> tagIds;
  final List<Map<String, dynamic>> teams;
  final List<Comment> comments;
  final List<Attachment> attachments;
  final Map<String, dynamic> customFieldValues;
  final DateTime createdAt;
  final bool isActive;

  const Account({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.website,
    this.industry = AccountIndustry.none,
    this.numberOfEmployees,
    this.annualRevenue,
    this.currency,
    this.addressLine,
    this.city,
    this.state,
    this.postcode,
    this.country,
    this.description,
    this.assignedTo = const [],
    this.assignedToIds = const [],
    this.tags = const [],
    this.tagIds = const [],
    this.teams = const [],
    this.comments = const [],
    this.attachments = const [],
    this.customFieldValues = const {},
    required this.createdAt,
    this.isActive = true,
  });

  String get initials {
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  String get assignedToName {
    if (assignedTo.isEmpty) return 'Unassigned';
    final first = assignedTo.first;
    final details = first['user_details'];
    if (details is Map<String, dynamic>) {
      final name = (details['name'] as String?)?.trim() ?? '';
      if (name.isNotEmpty) return name;
      final email = (details['email'] as String?)?.trim() ?? '';
      if (email.isNotEmpty) return email.split('@').first;
    }
    return 'Unknown';
  }

  String? get assignedToProfilePic {
    if (assignedTo.isEmpty) return null;
    final details = assignedTo.first['user_details'];
    if (details is Map<String, dynamic>) {
      return (details['profile_pic'] as String?)?.trim();
    }
    return null;
  }

  factory Account.fromJson(Map<String, dynamic> json) {
    // Parse assigned_to
    List<Map<String, dynamic>> parsedAssignedTo = [];
    List<String> parsedAssignedToIds = [];
    if (json['assigned_to'] is List) {
      for (final a in json['assigned_to'] as List) {
        if (a is Map<String, dynamic>) {
          parsedAssignedTo.add(a);
          final id = a['id']?.toString() ?? '';
          if (id.isNotEmpty) parsedAssignedToIds.add(id);
        }
      }
    }

    // Parse tags
    List<String> parsedTags = [];
    List<String> parsedTagIds = [];
    if (json['tags'] is List) {
      for (final t in json['tags'] as List) {
        if (t is Map<String, dynamic>) {
          final n = t['name'] as String?;
          if (n != null && n.isNotEmpty) parsedTags.add(n);
          final tid = t['id']?.toString();
          if (tid != null && tid.isNotEmpty) parsedTagIds.add(tid);
        } else if (t is String) {
          parsedTags.add(t);
        }
      }
    }

    // Parse teams
    List<Map<String, dynamic>> parsedTeams = [];
    if (json['teams'] is List) {
      for (final t in json['teams'] as List) {
        if (t is Map<String, dynamic>) parsedTeams.add(t);
      }
    }

    // Parse custom fields
    Map<String, dynamic> parsedCustomFields = const {};
    if (json['custom_fields'] is Map) {
      parsedCustomFields = Map<String, dynamic>.from(json['custom_fields'] as Map);
    }

    // Parse annual_revenue
    double? revenue;
    if (json['annual_revenue'] != null) {
      if (json['annual_revenue'] is num) {
        revenue = (json['annual_revenue'] as num).toDouble();
      } else if (json['annual_revenue'] is String) {
        revenue = double.tryParse(json['annual_revenue'] as String);
      }
    }

    return Account(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      industry: AccountIndustry.fromString(json['industry'] as String?),
      numberOfEmployees: json['number_of_employees'] as int?,
      annualRevenue: revenue,
      currency: json['currency'] as String?,
      addressLine: json['address_line'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      postcode: json['postcode'] as String?,
      country: json['country'] as String?,
      description: json['description'] as String?,
      assignedTo: parsedAssignedTo,
      assignedToIds: parsedAssignedToIds,
      tags: parsedTags,
      tagIds: parsedTagIds,
      teams: parsedTeams,
      customFieldValues: parsedCustomFields,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'website': website,
      'industry': industry.value,
      'number_of_employees': numberOfEmployees,
      'annual_revenue': annualRevenue?.toString(),
      'currency': currency,
      'address_line': addressLine,
      'city': city,
      'state': state,
      'postcode': postcode,
      'country': country,
      'description': description,
      'is_active': isActive,
      if (assignedToIds.isNotEmpty) 'assigned_to': assignedToIds,
      if (tagIds.isNotEmpty) 'tags': tagIds,
      if (customFieldValues.isNotEmpty) 'custom_fields': customFieldValues,
    };
  }

  Account copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? website,
    AccountIndustry? industry,
    int? numberOfEmployees,
    double? annualRevenue,
    String? currency,
    String? addressLine,
    String? city,
    String? state,
    String? postcode,
    String? country,
    String? description,
    List<Map<String, dynamic>>? assignedTo,
    List<String>? assignedToIds,
    List<String>? tags,
    List<String>? tagIds,
    List<Map<String, dynamic>>? teams,
    List<Comment>? comments,
    List<Attachment>? attachments,
    Map<String, dynamic>? customFieldValues,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      industry: industry ?? this.industry,
      numberOfEmployees: numberOfEmployees ?? this.numberOfEmployees,
      annualRevenue: annualRevenue ?? this.annualRevenue,
      currency: currency ?? this.currency,
      addressLine: addressLine ?? this.addressLine,
      city: city ?? this.city,
      state: state ?? this.state,
      postcode: postcode ?? this.postcode,
      country: country ?? this.country,
      description: description ?? this.description,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToIds: assignedToIds ?? this.assignedToIds,
      tags: tags ?? this.tags,
      tagIds: tagIds ?? this.tagIds,
      teams: teams ?? this.teams,
      comments: comments ?? this.comments,
      attachments: attachments ?? this.attachments,
      customFieldValues: customFieldValues ?? this.customFieldValues,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Account && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
