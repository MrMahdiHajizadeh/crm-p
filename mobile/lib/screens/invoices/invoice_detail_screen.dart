import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/theme.dart';
import '../../data/models/invoice.dart';
import '../../providers/invoices_provider.dart';
import '../../widgets/common/common.dart';

/// Invoice detail screen
class InvoiceDetailScreen extends ConsumerStatefulWidget {
  final String invoiceId;
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  ConsumerState<InvoiceDetailScreen> createState() =>
      _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends ConsumerState<InvoiceDetailScreen> {
  Invoice? _invoice;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final invoice =
          await ref.read(invoicesProvider.notifier).getInvoiceById(widget.invoiceId);
      if (mounted) {
        setState(() {
          _invoice = invoice;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'overdue':
        return Colors.red;
      case 'sent':
      case 'viewed':
        return Colors.orange;
      case 'draft':
      case 'pending':
        return Colors.grey;
      case 'cancelled':
        return Colors.red.shade300;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_invoice?.invoiceTitle ?? 'Invoice',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            )),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _invoice == null
                  ? const Center(child: Text('Invoice not found'))
                  : _buildContent(theme),
    );
  }

  Widget _buildContent(ThemeData theme) {
    final inv = _invoice!;
    final dateFormat = DateFormat.yMMMd();
    final currencyFormat = NumberFormat.currency(symbol: inv.currency);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(inv.status.icon,
                      size: 32,
                      color: _statusColor(inv.status.value)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(inv.invoiceTitle,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            )),
                        Text(inv.invoiceNumber,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            )),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _statusColor(inv.status.value).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      inv.status.label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: _statusColor(inv.status.value),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Client info
          _section(theme, 'Client', [
            _infoRow(
                theme, LucideIcons.user, 'Name', inv.clientName),
            _infoRow(
                theme, LucideIcons.mail, 'Email', inv.clientEmail),
            if (inv.accountName != null)
              _infoRow(theme, LucideIcons.building2, 'Account',
                  inv.accountName!),
          ]),
          const SizedBox(height: 16),

          // Financial summary
          _section(theme, 'Summary', [
            _infoRow(
                theme,
                LucideIcons.dollarSign,
                'Total',
                currencyFormat.format(inv.totalAmount)),
            _infoRow(
                theme,
                LucideIcons.checkCircle,
                'Paid',
                currencyFormat.format(inv.amountPaid)),
            _infoRow(
                theme,
                LucideIcons.alertCircle,
                'Due',
                currencyFormat.format(inv.amountDue),
                valueColor: inv.isOverdue
                    ? theme.colorScheme.error
                    : null),
          ]),
          const SizedBox(height: 16),

          // Dates
          _section(theme, 'Dates', [
            _infoRow(theme, LucideIcons.calendar, 'Issue Date',
                dateFormat.format(inv.issueDate)),
            if (inv.dueDate != null)
              _infoRow(theme, LucideIcons.calendarDays, 'Due Date',
                  dateFormat.format(inv.dueDate!)),
            if (inv.isOverdue)
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: Chip(
                  avatar: const Icon(Icons.warning, size: 16),
                  label: const Text('Overdue'),
                  backgroundColor:
                      theme.colorScheme.errorContainer,
                  labelStyle: TextStyle(
                    color: theme.colorScheme.onErrorContainer,
                    fontSize: 12,
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize:
                      MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ]),
          const SizedBox(height: 16),

          // Line items count
          if (inv.lineItemsCount > 0)
            _section(theme, 'Items', [
              _infoRow(theme, LucideIcons.list, 'Line Items',
                  '${inv.lineItemsCount}'),
            ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _section(ThemeData theme, String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                )),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    ThemeData theme,
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
          ),
          Expanded(
            child: Text(value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: valueColor,
                )),
          ),
        ],
      ),
    );
  }
}
