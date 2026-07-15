import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/api_config.dart';
import '../data/models/account.dart';
import '../data/models/attachment.dart';
import '../data/models/comment.dart';
import '../services/api_service.dart';

/// Paginated accounts snapshot
class AccountsListData {
  final List<Account> accounts;
  final int totalCount;
  final bool hasMore;
  final int currentOffset;

  const AccountsListData({
    this.accounts = const [],
    this.totalCount = 0,
    this.hasMore = true,
    this.currentOffset = 0,
  });

  AccountsListData copyWith({
    List<Account>? accounts,
    int? totalCount,
    bool? hasMore,
    int? currentOffset,
  }) {
    return AccountsListData(
      accounts: accounts ?? this.accounts,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
      currentOffset: currentOffset ?? this.currentOffset,
    );
  }
}

class AccountsNotifier extends AsyncNotifier<AccountsListData> {
  final ApiService _apiService = ApiService();
  static const int _pageSize = 20;

  @override
  Future<AccountsListData> build() => _fetchPage(offset: 0);

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
        accounts: [...current.accounts, ...next.accounts],
        totalCount: next.totalCount,
        hasMore: next.hasMore,
        currentOffset: next.currentOffset,
      );
    });
  }

  Future<AccountsListData> _fetchPage({required int offset}) async {
    final queryParams = <String, String>{
      'limit': _pageSize.toString(),
      'offset': offset.toString(),
    };

    final url = Uri.parse(
      ApiConfig.accounts,
    ).replace(queryParameters: queryParams).toString();
    final response = await _apiService.get(url);

    if (!response.success || response.data == null) {
      throw Exception(response.message ?? 'Failed to load accounts');
    }

    final data = response.data!;

    // Backend returns nested active_accounts sub-object with open_accounts
    List<dynamic> accountsList = [];
    int accountsCount = 0;
    final activeData = data['active_accounts'] as Map<String, dynamic>?;
    if (activeData != null) {
      accountsList = activeData['open_accounts'] as List<dynamic>? ?? [];
      accountsCount = activeData['open_accounts_count'] as int? ?? accountsList.length;
    } else if (data['accounts'] is List) {
      accountsList = data['accounts'] as List<dynamic>;
      accountsCount = data['accounts_count'] as int? ?? accountsList.length;
    } else if (data['results'] is List) {
      accountsList = data['results'] as List<dynamic>;
      accountsCount = data['count'] as int? ?? accountsList.length;
    }

    final newAccounts = accountsList
        .whereType<Map<String, dynamic>>()
        .map(Account.fromJson)
        .toList();

    final nextOffset = data['offset'] as int? ??
        activeData?['offset'] as int?;

    return AccountsListData(
      accounts: newAccounts,
      totalCount: accountsCount,
      hasMore: nextOffset != null,
      currentOffset: nextOffset ?? (offset + newAccounts.length),
    );
  }

  Future<Account?> getAccountById(String id) async {
    try {
      final url = '${ApiConfig.accounts}$id/';
      final response = await _apiService.get(url);
      if (!response.success || response.data == null) return null;

      final data = response.data!;
      final accountData = data['account_obj'] as Map<String, dynamic>?;
      if (accountData == null) return null;

      Account account = Account.fromJson(accountData);

      // Merge top-level comments and attachments
      try {
        final commentsData = data['comments'] as List<dynamic>?;
        if (commentsData != null) {
          final parsed = commentsData
              .whereType<Map<String, dynamic>>()
              .map(Comment.fromJson)
              .toList();
          account = account.copyWith(comments: parsed);
        }
      } catch (_) {}

      try {
        final attachmentsData = data['attachments'] as List<dynamic>?;
        if (attachmentsData != null) {
          final parsed = attachmentsData
              .whereType<Map<String, dynamic>>()
              .map(Attachment.fromJson)
              .toList();
          account = account.copyWith(attachments: parsed);
        }
      } catch (_) {}

      return account;
    } catch (e) {
      return null;
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> createAccount(
    Map<String, dynamic> accountData,
  ) async {
    try {
      final response = await _apiService.post(ApiConfig.accounts, accountData);
      if (response.success) await refresh();
      return response;
    } catch (e) {
      return ApiResponse(success: false, message: e.toString(), statusCode: 0);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> updateAccount(
    String id,
    Map<String, dynamic> accountData,
  ) async {
    try {
      final url = '${ApiConfig.accounts}$id/';
      // PATCH to avoid backend PUT handler clearing M2M fields
      final response = await _apiService.patch(url, accountData);
      if (response.success) await refresh();
      return response;
    } catch (e) {
      return ApiResponse(success: false, message: e.toString(), statusCode: 0);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> deleteAccount(String id) async {
    try {
      final url = '${ApiConfig.accounts}$id/';
      final response = await _apiService.delete(url);

      if (response.success) {
        final current = state.value;
        if (current != null) {
          state = AsyncValue.data(
            current.copyWith(
              accounts: current.accounts.where((a) => a.id != id).toList(),
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

final accountsProvider = AsyncNotifierProvider<AccountsNotifier, AccountsListData>(
  AccountsNotifier.new,
);
