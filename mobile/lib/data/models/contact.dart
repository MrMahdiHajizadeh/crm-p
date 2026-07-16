import 'comment.dart';
import 'attachment.dart';

/// Contact model for BottleCRM
class Contact {
  final String id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String? organization;
  final String? title;
  final String? department;
  final bool doNotCall;
  final String? linkedinUrl;
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
  final String? accountId;
  final String? accountName;
  final List<Comment> comments;
  final List<Attachment> attachments;
  final Map<String, dynamic> customFieldValues;
  final DateTime createdAt;
  final bool isActive;

  const Contact({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    this.organization,
    this.title,
    this.department,
    this.doNotCall = false,
    this.linkedinUrl,
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
    this.accountId,
    this.accountName,
    this.comments = const [],
    this.attachments = const [],
    this.customFieldValues = const {},
    required this.createdAt,
    this.isActive = true,
  });

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final first = firstName.isNotEmpty ? firstName[0] : '';
    final last = lastName.isNotEmpty ? lastName[0] : '';
    if (first.isNotEmpty || last.isNotEmpty) {
      return '$first$last'.toUpperCase();
    }
    return email?.substring(0, 2).toUpperCase() ?? '?';
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

  factory Contact.fromJson(Map<String, dynamic> json) {
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

    // Parse tags — ContactSerializer returns PKs (UUID strings), not objects
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
          parsedTagIds.add(t);
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

    // Parse account
    String? accountId;
    String? accountName;
    if (json['account'] is Map<String, dynamic>) {
      accountId = (json['account'] as Map<String, dynamic>)['id']?.toString();
      accountName = (json['account'] as Map<String, dynamic>)['name'] as String?;
    } else if (json['account'] is String) {
      accountId = json['account'] as String;
    }

    // Parse custom fields
    Map<String, dynamic> parsedCustomFields = const {};
    if (json['custom_fields'] is Map) {
      parsedCustomFields = Map<String, dynamic>.from(json['custom_fields'] as Map);
    }

    return Contact(
      id: json['id']?.toString() ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      organization: json['organization'] as String?,
      title: json['title'] as String?,
      department: json['department'] as String?,
      doNotCall: json['do_not_call'] as bool? ?? false,
      linkedinUrl: json['linkedin_url'] as String?,
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
      accountId: accountId,
      accountName: accountName,
      customFieldValues: parsedCustomFields,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'organization': organization,
      'title': title,
      'department': department,
      'do_not_call': doNotCall,
      'linkedin_url': linkedinUrl,
      'address_line': addressLine,
      'city': city,
      'state': state,
      'postcode': postcode,
      'country': country,
      'description': description,
      'account': accountId,
      'is_active': isActive,
      if (assignedToIds.isNotEmpty) 'assigned_to': assignedToIds,
      if (tagIds.isNotEmpty) 'tags': tagIds,
      if (customFieldValues.isNotEmpty) 'custom_fields': customFieldValues,
    };
  }

  Contact copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? organization,
    String? title,
    String? department,
    bool? doNotCall,
    String? linkedinUrl,
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
    String? accountId,
    String? accountName,
    List<Comment>? comments,
    List<Attachment>? attachments,
    Map<String, dynamic>? customFieldValues,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Contact(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      organization: organization ?? this.organization,
      title: title ?? this.title,
      department: department ?? this.department,
      doNotCall: doNotCall ?? this.doNotCall,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
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
      accountId: accountId ?? this.accountId,
      accountName: accountName ?? this.accountName,
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
      other is Contact && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
