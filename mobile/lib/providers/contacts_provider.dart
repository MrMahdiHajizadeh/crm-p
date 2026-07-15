import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/api_config.dart';
import '../data/models/contact.dart';
import '../data/models/attachment.dart';
import '../data/models/comment.dart';
import '../services/api_service.dart';

/// Paginated contacts snapshot
class ContactsListData {
  final List<Contact> contacts;
  final int totalCount;
  final bool hasMore;
  final int currentOffset;

  const ContactsListData({
    this.contacts = const [],
    this.totalCount = 0,
    this.hasMore = true,
    this.currentOffset = 0,
  });

  ContactsListData copyWith({
    List<Contact>? contacts,
    int? totalCount,
    bool? hasMore,
    int? currentOffset,
  }) {
    return ContactsListData(
      contacts: contacts ?? this.contacts,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
      currentOffset: currentOffset ?? this.currentOffset,
    );
  }
}

class ContactsNotifier extends AsyncNotifier<ContactsListData> {
  final ApiService _apiService = ApiService();
  static const int _pageSize = 20;

  @override
  Future<ContactsListData> build() => _fetchPage(offset: 0);

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchPage(offset: 0));
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore) return;
    if (state.isLoading) return;

    state = await AsyncValue.guard(() async {
      final next = await _fetchPage(offset: current.currentOffset);
      return current.copyWith(
        contacts: [...current.contacts, ...next.contacts],
        totalCount: next.totalCount,
        hasMore: next.hasMore,
        currentOffset: next.currentOffset,
      );
    });
  }

  Future<ContactsListData> _fetchPage({required int offset}) async {
    final queryParams = <String, String>{
      'limit': _pageSize.toString(),
      'offset': offset.toString(),
    };

    final url = Uri.parse(
      ApiConfig.contacts,
    ).replace(queryParameters: queryParams).toString();
    final response = await _apiService.get(url);

    if (!response.success || response.data == null) {
      throw Exception(response.message ?? 'Failed to load contacts');
    }

    final data = response.data!;

    // Backend returns contacts under various keys
    List<dynamic> contactsList = [];
    int contactsCount = 0;

    if (data['contact_obj_list'] is List) {
      contactsList = data['contact_obj_list'] as List<dynamic>;
      contactsCount = data['contacts_count'] as int? ?? contactsList.length;
    } else if (data['contacts'] is List) {
      contactsList = data['contacts'] as List<dynamic>;
      contactsCount = data['contacts_count'] as int? ?? contactsList.length;
    } else if (data['results'] is List) {
      contactsList = data['results'] as List<dynamic>;
      contactsCount = data['count'] as int? ?? contactsList.length;
    }

    final newContacts = contactsList
        .whereType<Map<String, dynamic>>()
        .map(Contact.fromJson)
        .toList();

    final nextOffset = data['offset'] as int?;

    return ContactsListData(
      contacts: newContacts,
      totalCount: contactsCount,
      hasMore: nextOffset != null,
      currentOffset: nextOffset ?? (offset + newContacts.length),
    );
  }

  Future<Contact?> getContactById(String id) async {
    try {
      final url = '${ApiConfig.contacts}$id/';
      final response = await _apiService.get(url);
      if (!response.success || response.data == null) return null;

      final data = response.data!;
      final contactData = data['contact_obj'] as Map<String, dynamic>?;
      if (contactData == null) return null;

      Contact contact = Contact.fromJson(contactData);

      try {
        final commentsData = data['comments'] as List<dynamic>?;
        if (commentsData != null) {
          final parsed = commentsData
              .whereType<Map<String, dynamic>>()
              .map(Comment.fromJson)
              .toList();
          contact = contact.copyWith(comments: parsed);
        }
      } catch (_) {}

      try {
        final attachmentsData = data['attachments'] as List<dynamic>?;
        if (attachmentsData != null) {
          final parsed = attachmentsData
              .whereType<Map<String, dynamic>>()
              .map(Attachment.fromJson)
              .toList();
          contact = contact.copyWith(attachments: parsed);
        }
      } catch (_) {}

      return contact;
    } catch (e) {
      return null;
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> createContact(
    Map<String, dynamic> contactData,
  ) async {
    try {
      final response = await _apiService.post(ApiConfig.contacts, contactData);
      if (response.success) await refresh();
      return response;
    } catch (e) {
      return ApiResponse(success: false, message: e.toString(), statusCode: 0);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> updateContact(
    String id,
    Map<String, dynamic> contactData,
  ) async {
    try {
      final url = '${ApiConfig.contacts}$id/';
      // PATCH to avoid backend PUT handler clearing M2M fields
      final response = await _apiService.patch(url, contactData);
      if (response.success) await refresh();
      return response;
    } catch (e) {
      return ApiResponse(success: false, message: e.toString(), statusCode: 0);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> deleteContact(String id) async {
    try {
      final url = '${ApiConfig.contacts}$id/';
      final response = await _apiService.delete(url);

      if (response.success) {
        final current = state.value;
        if (current != null) {
          state = AsyncValue.data(
            current.copyWith(
              contacts: current.contacts.where((c) => c.id != id).toList(),
              totalCount: current.totalCount - 1,
            ),
          );
        }
      }
      return response;
    } catch (e) {
      return ApiResponse(success: false, message: e.toString(), statusCode: 0);
    }
  }
}

final contactsProvider = AsyncNotifierProvider<ContactsNotifier, ContactsListData>(
  ContactsNotifier.new,
);
