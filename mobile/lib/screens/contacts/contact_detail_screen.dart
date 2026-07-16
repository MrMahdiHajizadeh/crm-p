import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../data/models/contact.dart';
import '../../providers/contacts_provider.dart';

/// Contact detail screen
class ContactDetailScreen extends ConsumerStatefulWidget {
  final String contactId;
  const ContactDetailScreen({super.key, required this.contactId});

  @override
  ConsumerState<ContactDetailScreen> createState() =>
      _ContactDetailScreenState();
}

class _ContactDetailScreenState extends ConsumerState<ContactDetailScreen> {
  Contact? _contact;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContact();
  }

  Future<void> _loadContact() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final contact =
          await ref.read(contactsProvider.notifier).getContactById(widget.contactId);
      if (mounted) {
        setState(() {
          _contact = contact;
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
        title: Text(_contact?.fullName ?? 'Contact',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            )),
        actions: [
          if (_contact != null)
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
              : _contact == null
                  ? const Center(child: Text('Contact not found'))
                  : _buildContent(theme),
    );
  }

  void _confirmDelete() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text(
            'Are you sure you want to delete "${_contact!.fullName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(contactsProvider.notifier)
                  .deleteContact(widget.contactId);
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
    final c = _contact!;
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
                    child: Text(c.initials,
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
                        Text(c.fullName,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            )),
                        if (c.title != null)
                          Text(c.title!,
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
            _infoRow(theme, LucideIcons.mail, 'Email', c.email ?? '—'),
            _infoRow(theme, LucideIcons.phone, 'Phone', c.phone ?? '—'),
            _infoRow(theme, LucideIcons.building2, 'Company',
                c.organization ?? '—'),
            _infoRow(theme, LucideIcons.briefcase, 'Department',
                c.department ?? '—'),
            _infoRow(
                theme, LucideIcons.link, 'LinkedIn', c.linkedinUrl ?? '—'),
          ]),
          const SizedBox(height: 16),

          // Address
          _section(theme, 'Address', [
            _infoRow(theme, LucideIcons.mapPin, 'Street',
                c.addressLine ?? '—'),
            _infoRow(theme, LucideIcons.mapPin, 'City', c.city ?? '—'),
            _infoRow(theme, LucideIcons.map, 'State', c.state ?? '—'),
            _infoRow(theme, LucideIcons.mail, 'Postcode',
                c.postcode ?? '—'),
            _infoRow(
                theme, LucideIcons.flag, 'Country', c.country ?? '—'),
          ]),
          const SizedBox(height: 16),

          // Account
          if (c.accountName != null)
            _section(theme, 'Account', [
              _infoRow(theme, LucideIcons.building2, 'Account',
                  c.accountName!),
            ]),
          const SizedBox(height: 16),

          // Description
          if (c.description != null && c.description!.isNotEmpty)
            _section(theme, 'Description', [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(c.description!,
                    style: theme.textTheme.bodyMedium),
              ),
            ]),
          const SizedBox(height: 16),

          // Assignee
          _section(theme, 'Assigned To', [
            _infoRow(theme, LucideIcons.userCheck, 'Assignee',
                c.assignedToName),
          ]),
          const SizedBox(height: 16),

          // Tags
          if (c.tags.isNotEmpty)
            _section(theme, 'Tags', [
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: c.tags
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
                dateFormat.format(c.createdAt)),
            _infoRow(theme, LucideIcons.eye, 'Status',
                c.isActive ? 'Active' : 'Inactive'),
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
