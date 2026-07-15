import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/api_config.dart';
import '../data/models/invoice.dart';
import '../services/api_service.dart';

/// Paginated invoices snapshot
class InvoicesListData {
  final List<Invoice> invoices;
  final int totalCount;
  final bool hasMore;
  final int currentOffset;

  const InvoicesListData({
    this.invoices = const [],
    this.totalCount = 0,
    this.hasMore = true,
    this.currentOffset = 0,
  });

  InvoicesListData copyWith({
    List<Invoice>? invoices,
    int? totalCount,
    bool? hasMore,
    int? currentOffset,
  }) {
    return InvoicesListData(
      invoices: invoices ?? this.invoices,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
      currentOffset: currentOffset ?? this.currentOffset,
    );
  }
}

class InvoicesNotifier extends AsyncNotifier<InvoicesListData> {
  final ApiService _apiService = ApiService();
  static const int _pageSize = 20;

  @override
  Future<InvoicesListData> build() => _fetchPage(offset: 0);

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
        invoices: [...current.invoices, ...next.invoices],
        totalCount: next.totalCount,
        hasMore: next.hasMore,
        currentOffset: next.currentOffset,
      );
    });
  }

  Future<InvoicesListData> _fetchPage({required int offset}) async {
    final queryParams = <String, String>{
      'limit': _pageSize.toString(),
      'offset': offset.toString(),
    };

    final url = Uri.parse(
      ApiConfig.invoices,
    ).replace(queryParameters: queryParams).toString();
    final response = await _apiService.get(url);

    if (!response.success || response.data == null) {
      throw Exception(response.message ?? 'Failed to load invoices');
    }

    final data = response.data!;

    List<dynamic> invoicesList = [];
    int invoicesCount = 0;

    if (data['invoices'] is List) {
      invoicesList = data['invoices'] as List<dynamic>;
      invoicesCount = data['invoices_count'] as int? ?? invoicesList.length;
    } else if (data['results'] is List) {
      invoicesList = data['results'] as List<dynamic>;
      invoicesCount = data['count'] as int? ?? invoicesList.length;
    }

    final newInvoices = invoicesList
        .whereType<Map<String, dynamic>>()
        .map(Invoice.fromJson)
        .toList();

    final nextOffset = data['offset'] as int?;

    return InvoicesListData(
      invoices: newInvoices,
      totalCount: invoicesCount,
      hasMore: nextOffset != null,
      currentOffset: nextOffset ?? (offset + newInvoices.length),
    );
  }

  Future<Invoice?> getInvoiceById(String id) async {
    try {
      final url = '${ApiConfig.invoices}$id/';
      final response = await _apiService.get(url);
      if (!response.success || response.data == null) return null;

      return Invoice.fromJson(response.data!);
    } catch (e) {
      return null;
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> updateInvoiceStatus(
    String id,
    String status,
  ) async {
    try {
      final url = '${ApiConfig.invoices}$id/';
      final response = await _apiService.patch(url, {'status': status});
      if (response.success) await refresh();
      return response;
    } catch (e) {
      return ApiResponse(success: false, message: e.toString(), statusCode: 0);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> deleteInvoice(String id) async {
    try {
      final url = '${ApiConfig.invoices}$id/';
      final response = await _apiService.delete(url);

      if (response.success) {
        final current = state.value;
        if (current != null) {
          state = AsyncValue.data(
            current.copyWith(
              invoices: current.invoices.where((i) => i.id != id).toList(),
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

final invoicesProvider = AsyncNotifierProvider<InvoicesNotifier, InvoicesListData>(
  InvoicesNotifier.new,
);
