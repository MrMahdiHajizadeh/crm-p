import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../core/theme/theme.dart';
import '../../data/models/follow_up.dart';
import '../../providers/follow_ups_provider.dart';
import '../../widgets/common/common.dart';

class FollowUpsScreen extends ConsumerStatefulWidget {
  const FollowUpsScreen({super.key});

  @override
  ConsumerState<FollowUpsScreen> createState() => _FollowUpsScreenState();
}

class _FollowUpsScreenState extends ConsumerState<FollowUpsScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(followUpsProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceDim,
      appBar: AppBar(
        title: const Text('Follow-ups'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevron_left),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              state.myOnly ? LucideIcons.sliders_horizontal : LucideIcons.sliders_horizontal,
              color: state.myOnly ? AppColors.primary600 : AppColors.textSecondary,
            ),
            onPressed: () => ref.read(followUpsProvider.notifier).toggleMyOnly(),
            tooltip: state.myOnly ? 'Show all follow-ups' : 'Show my follow-ups only',
          ),
          IconButton(
            icon: const Icon(LucideIcons.refresh_cw),
            onPressed: () => ref.read(followUpsProvider.notifier).load(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: state.isLoading && state.groups.values.every((list) => list.isEmpty)
          ? const Center(child: CircularProgressIndicator())
          : state.errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.circle_alert, size: 48, color: AppColors.danger500),
                        const SizedBox(height: 16),
                        Text(
                          state.errorMessage!,
                          textAlign: TextAlign.center,
                          style: AppTypography.body,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.read(followUpsProvider.notifier).load(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildGroupedList(state.groups),
    );
  }

  Widget _buildGroupedList(Map<String, List<FollowUp>> groups) {
    final totalCount = groups.values.fold(0, (sum, list) => sum + list.length);

    if (totalCount == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.calendar, size: 64, color: AppColors.gray400),
              const SizedBox(height: 16),
              Text('All Caught Up!', style: AppTypography.h3),
              const SizedBox(height: 8),
              Text(
                'No pending follow-ups found. Great job!',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final List<Widget> children = [];

    final groupConfigs = [
      _GroupConfig('overdue', 'Overdue', LucideIcons.triangle_alert, AppColors.danger500, AppColors.danger50),
      _GroupConfig('today', 'Today', LucideIcons.clock, AppColors.warning500, AppColors.warning50),
      _GroupConfig('tomorrow', 'Tomorrow', LucideIcons.calendar, AppColors.primary500, AppColors.primary50),
      _GroupConfig('thisWeek', 'This Week', LucideIcons.calendar_days, AppColors.purple500, AppColors.purple50),
      _GroupConfig('later', 'Later', LucideIcons.calendar_clock, AppColors.textSecondary, AppColors.gray100),
    ];

    for (final config in groupConfigs) {
      final list = groups[config.key] ?? [];
      if (list.isNotEmpty) {
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(config.icon, size: 16, color: config.color),
                const SizedBox(width: 8),
                Text(
                  config.label,
                  style: AppTypography.overline.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.gray200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    list.length.toString(),
                    style: AppTypography.caption.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        for (final item in list) {
          children.add(
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.gray200),
              ),
              color: AppColors.surface,
              elevation: 0,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  // Navigate to the detail view of the associated entity
                  context.push(item.routePath);
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(item.entityIcon, size: 12, color: AppColors.primary600),
                                const SizedBox(width: 4),
                                Text(
                                  item.entityType.toUpperCase(),
                                  style: AppTypography.caption.copyWith(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.entityName,
                              style: AppTypography.body.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: Icon(LucideIcons.square_check, color: AppColors.success500),
                            onPressed: () => _showInteractionLogDialog(item),
                            tooltip: 'Complete follow-up',
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                      if (item.subject != null && item.subject!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          item.subject!,
                          style: AppTypography.body.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ],
                      if (item.description != null && item.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.description!,
                          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(item.interactionType.icon, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            item.interactionType.label,
                            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                          ),
                          if (item.durationMinutes != null) ...[
                            const SizedBox(width: 12),
                            Icon(LucideIcons.hourglass, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              '${item.durationMinutes}m',
                              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                          const Spacer(),
                          if (item.followUpDate != null)
                            Text(
                              DateFormat('MMM d, h:mm a').format(item.followUpDate!.toLocal()),
                              style: AppTypography.caption.copyWith(
                                color: config.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      }
    }

    children.add(const SizedBox(height: 32));

    return ListView(
      children: children,
    );
  }

  void _showInteractionLogDialog(FollowUp item) {
    showDialog(
      context: context,
      builder: (context) => _InteractionLogDialog(
        followUp: item,
        onSuccess: () => ref.read(followUpsProvider.notifier).load(),
      ),
    );
  }
}

class _GroupConfig {
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;

  _GroupConfig(this.key, this.label, this.icon, this.color, this.bgColor);
}

class _InteractionLogDialog extends ConsumerStatefulWidget {
  final FollowUp followUp;
  final VoidCallback onSuccess;

  const _InteractionLogDialog({
    required this.followUp,
    required this.onSuccess,
  });

  @override
  ConsumerState<_InteractionLogDialog> createState() => _InteractionLogDialogState();
}

class _InteractionLogDialogState extends ConsumerState<_InteractionLogDialog> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descController = TextEditingController();
  final _durationController = TextEditingController();
  final _resultController = TextEditingController();
  
  FollowUpType _type = FollowUpType.call;
  DateTime? _nextFollowUpDate;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _type = widget.followUp.interactionType;
    _subjectController.text = 'Follow-up on ${widget.followUp.entityName}';
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descController.dispose();
    _durationController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Log Interaction', style: AppTypography.h3),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Complete your follow-up with ${widget.followUp.entityName} by logging the outcome.',
                style: AppTypography.caption,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<FollowUpType>(
                value: _type,
                decoration: const InputDecoration(
                  labelText: 'Interaction Type',
                  border: OutlineInputBorder(),
                ),
                items: FollowUpType.values.map((t) {
                  return DropdownMenuItem<FollowUpType>(
                    value: t,
                    child: Row(
                      children: [
                        Icon(t.icon, size: 18),
                        const SizedBox(width: 8),
                        Text(t.label),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _type = val);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Subject is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Outcome / Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _durationController,
                      decoration: const InputDecoration(
                        labelText: 'Duration (mins)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _resultController,
                      decoration: const InputDecoration(
                        labelText: 'Result (e.g. Busy)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Schedule Next Follow-up?'),
                subtitle: Text(
                  _nextFollowUpDate == null
                      ? 'No next follow-up scheduled'
                      : DateFormat('yyyy-MM-dd').format(_nextFollowUpDate!),
                ),
                trailing: IconButton(
                  icon: const Icon(LucideIcons.calendar),
                  onPressed: _pickNextFollowUp,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success600,
            foregroundColor: Colors.white,
          ),
          child: _submitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Save & Complete'),
        ),
      ],
    );
  }

  Future<void> _pickNextFollowUp() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _nextFollowUpDate = date);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    final duration = int.tryParse(_durationController.text);
    final nextDateIso = _nextFollowUpDate != null 
        ? '${DateFormat('yyyy-MM-dd').format(_nextFollowUpDate!)}T10:00:00Z'
        : null;

    final success = await ref.read(followUpsProvider.notifier).createInteraction(
          entityType: widget.followUp.entityType,
          entityId: widget.followUp.entityId,
          interactionType: _type.value,
          subject: _subjectController.text,
          description: _descController.text,
          interactionDate: DateTime.now().toUtc().toIso8601String(),
          durationMinutes: duration,
          result: _resultController.text,
          followUpDate: nextDateIso,
          completedInteractionId: widget.followUp.id,
        );

    setState(() => _submitting = false);
    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      widget.onSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Follow-up completed and logged.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success600,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to complete follow-up.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.danger600,
        ),
      );
    }
  }
}
