import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/contact.dart';
import '../../providers/contacts_provider.dart';

/// Contact create/edit form screen
class ContactFormScreen extends ConsumerStatefulWidget {
  final String? contactId;
  final Contact? contact;
  const ContactFormScreen({super.key, this.contactId, this.contact});

  @override
  ConsumerState<ContactFormScreen> createState() => _ContactFormScreenState();
}

class _ContactFormScreenState extends ConsumerState<ContactFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _organizationController;
  late final TextEditingController _titleController;
  late final TextEditingController _departmentController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _postcodeController;
  late final TextEditingController _descriptionController;

  bool _isSaving = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.contact != null;
    final c = widget.contact;
    _firstNameController = TextEditingController(text: c?.firstName ?? '');
    _lastNameController = TextEditingController(text: c?.lastName ?? '');
    _emailController = TextEditingController(text: c?.email ?? '');
    _phoneController = TextEditingController(text: c?.phone ?? '');
    _organizationController =
        TextEditingController(text: c?.organization ?? '');
    _titleController = TextEditingController(text: c?.title ?? '');
    _departmentController = TextEditingController(text: c?.department ?? '');
    _addressController = TextEditingController(text: c?.addressLine ?? '');
    _cityController = TextEditingController(text: c?.city ?? '');
    _stateController = TextEditingController(text: c?.state ?? '');
    _postcodeController = TextEditingController(text: c?.postcode ?? '');
    _descriptionController = TextEditingController(text: c?.description ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _organizationController.dispose();
    _titleController.dispose();
    _departmentController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postcodeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final data = {
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'email': _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      'phone': _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      'organization': _organizationController.text.trim().isEmpty
          ? null
          : _organizationController.text.trim(),
      'title': _titleController.text.trim().isEmpty
          ? null
          : _titleController.text.trim(),
      'department': _departmentController.text.trim().isEmpty
          ? null
          : _departmentController.text.trim(),
      'address_line': _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      'city': _cityController.text.trim().isEmpty
          ? null
          : _cityController.text.trim(),
      'state': _stateController.text.trim().isEmpty
          ? null
          : _stateController.text.trim(),
      'postcode': _postcodeController.text.trim().isEmpty
          ? null
          : _postcodeController.text.trim(),
      'description': _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
    };

    try {
      final response = _isEditing
          ? await ref
              .read(contactsProvider.notifier)
              .updateContact(widget.contactId!, data)
          : await ref
              .read(contactsProvider.notifier)
              .createContact(data);

      if (!mounted) return;

      if (response.success) {
        context.pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Failed to save contact'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Contact' : 'New Contact',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            )),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'First Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Last Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _organizationController,
              decoration: const InputDecoration(
                labelText: 'Company',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Job Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _departmentController,
              decoration: const InputDecoration(
                labelText: 'Department',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _stateController,
                    decoration: const InputDecoration(
                      labelText: 'State',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _postcodeController,
              decoration: const InputDecoration(
                labelText: 'Postcode',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
