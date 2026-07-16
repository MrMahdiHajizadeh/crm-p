import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../data/models/account.dart';
import '../../providers/accounts_provider.dart';
/// Account detail screen
class AccountDetailScreen extends ConsumerStatefulWidget {
  final String accountId;
  const AccountDetailScreen({super.key, required this.accountId});

  @override
  ConsumerState<AccountDetailScreen> createState() =>
      _AccountDetailScreenState();
}

class _AccountDetailScreenState extends ConsumerState<AccountDetailScreen> {
  Account? _account;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  Future<void> _loadAccount() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final account =
          await ref.read(accountsProvider.notifier).getAccountById(widget.accountId);
      if (mounted) {
        setState(() {
          _account = account;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_account?.name ?? 'Account',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            )),
        actions: [
          if (_account != null)
            IconButton(
              icon: const Icon(LucideIcons.pencil),
              onPressed: () =>
                  context.push('/accounts/${widget.accountId}/edit'),
            ),
          if (_account != null)
            IconButton(
              icon: const Icon(LucideIcons.trash2),
              onPressed: () => _confirmDelete(),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _account == null
                  ? const Center(child: Text('Account not found'))
                  : _buildContent(theme),
    );
  }

  void _confirmDelete() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text('Are you sure you want to delete "${_account!.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(accountsProvider.notifier)
                  .deleteAccount(widget.accountId);
              if (context.mounted) context.pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    final a = _account!;
    final dateFormat = DateFormat.yMMMd();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(a.initials,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onPrimaryContainer,
                        )),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            )),
                        if (a.industry != AccountIndustry.none)
                          Text(a.industry.label,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Contact info
          _section(theme, 'Contact Information', [
            _infoRow(theme, LucideIcons.mail, 'Email', a.email ?? '—'),
            _infoRow(theme, LucideIcons.phone, 'Phone', a.phone ?? '—'),
            _infoRow(theme, LucideIcons.globe, 'Website', a.website ?? '—'),
          ]),
          const SizedBox(height: 16),

          // Address
          _section(theme, 'Address', [
            _infoRow(theme, LucideIcons.mapPin, 'Street', a.addressLine ?? '—'),
            _infoRow(theme, LucideIcons.mapPin, 'City', a.city ?? '—'),
            _infoRow(theme, LucideIcons.map, 'State', a.state ?? '—'),
            _infoRow(theme, LucideIcons.mail, 'Postcode', a.postcode ?? '—'),
            _infoRow(theme, LucideIcons.flag, 'Country', a.country ?? '—'),
          ]),
          const SizedBox(height: 16),

          // Business details
          _section(theme, 'Business Details', [
            if (a.annualRevenue != null)
              _infoRow(theme, LucideIcons.dollarSign, 'Annual Revenue',
                  '\$${NumberFormat('#,##0.00').format(a.annualRevenue!)}'),
            if (a.numberOfEmployees != null)
              _infoRow(theme, LucideIcons.users, 'Employees',
                  '${a.numberOfEmployees}'),
            if (a.currency != null)
              _infoRow(
                  theme, LucideIcons.currency, 'Currency', a.currency!),
          ]),
          const SizedBox(height: 16),

          // Description
          if (a.description != null && a.description!.isNotEmpty)
            _section(theme, 'Description', [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(a.description!,
                    style: theme.textTheme.bodyMedium),
              ),
            ]),
          const SizedBox(height: 16),

          // Assignee
          _section(theme, 'Assigned To', [
            _infoRow(theme, LucideIcons.userCheck, 'Assignee',
                a.assignedToName),
          ]),
          const SizedBox(height: 16),

          // Tags
          if (a.tags.isNotEmpty)
            _section(theme, 'Tags', [
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: a.tags
                      .map((t) => Chip(
                            label: Text(t,
                                style: theme.textTheme.labelSmall),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ))
                      .toList(),
                ),
              ),
            ]),
          const SizedBox(height: 16),

          // System info
          _section(theme, 'System', [
            _infoRow(theme, LucideIcons.calendar, 'Created',
                dateFormat.format(a.createdAt)),
            _infoRow(theme, LucideIcons.eye, 'Status',
                a.isActive ? 'Active' : 'Inactive'),
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
      ThemeData theme, IconData icon, String label, String value) {
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
                )),
          ),
        ],
      ),
    );
  }
}
