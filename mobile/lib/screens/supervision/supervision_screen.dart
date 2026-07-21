import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../core/theme/theme.dart';
import '../../data/models/supervision_activity.dart';
import '../../data/models/lookup_models.dart';
import '../../providers/supervision_provider.dart';
import '../../providers/lookup_provider.dart';
import '../../widgets/common/common.dart';

class SupervisionScreen extends ConsumerStatefulWidget {
  const SupervisionScreen({super.key});

  @override
  ConsumerState<SupervisionScreen> createState() => _SupervisionScreenState();
}

class _SupervisionScreenState extends ConsumerState<SupervisionScreen> {
  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd');
  bool _filtersExpanded = false;

  final List<Map<String, String>> _entityTypes = [
    {'value': '', 'label': 'All Types'},
    {'value': 'Lead', 'label': 'Lead'},
    {'value': 'Contact', 'label': 'Contact'},
    {'value': 'Account', 'label': 'Account'},
    {'value': 'Opportunity', 'label': 'Opportunity'},
    {'value': 'Case', 'label': 'Ticket'},
    {'value': 'Task', 'label': 'Task'},
    {'value': 'Invoice', 'label': 'Invoice'},
    {'value': 'Event', 'label': 'Event'},
    {'value': 'Document', 'label': 'Document'},
    {'value': 'Team', 'label': 'Team'},
  ];

  final List<Map<String, String>> _actionTypes = [
    {'value': '', 'label': 'All Actions'},
    {'value': 'CREATE', 'label': 'Create'},
    {'value': 'UPDATE', 'label': 'Update'},
    {'value': 'DELETE', 'label': 'Delete'},
    {'value': 'ASSIGN', 'label': 'Assign'},
    {'value': 'STATUS_CHANGED', 'label': 'Status Changed'},
    {'value': 'PRIORITY_CHANGED', 'label': 'Priority Changed'},
    {'value': 'APPROVED', 'label': 'Approved'},
    {'value': 'REJECTED', 'label': 'Rejected'},
    {'value': 'ESCALATED', 'label': 'Escalated'},
    {'value': 'ROUTED', 'label': 'Routed'},
    {'value': 'MERGED', 'label': 'Merged'},
    {'value': 'TIME_LOGGED', 'label': 'Time Logged'},
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(supervisionProvider);
    final usersList = ref.watch(usersProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceDim,
      appBar: AppBar(
        title: const Text('Supervision (Activities)'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevron_left),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(_filtersExpanded ? LucideIcons.sliders_horizontal : LucideIcons.sliders_horizontal),
            onPressed: () {
              setState(() => _filtersExpanded = !_filtersExpanded);
            },
            tooltip: 'Toggle filters',
          ),
          IconButton(
            icon: const Icon(LucideIcons.refresh_cw),
            onPressed: () => ref.read(supervisionProvider.notifier).load(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_filtersExpanded) _buildFiltersCard(state, usersList),
          _buildPaginationHeader(state),
          Expanded(
            child: state.isLoading && state.activities.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.circle_alert, size: 48, color: AppColors.danger500),
                            const SizedBox(height: 16),
                            Text(state.errorMessage!, style: AppTypography.body),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => ref.read(supervisionProvider.notifier).load(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _buildActivityList(state.activities),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersCard(SupervisionState state, List<UserLookup> users) {
    return Card(
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.gray200),
      ),
      elevation: 0,
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: state.entityType,
                    decoration: const InputDecoration(labelText: 'Entity Type', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8), border: OutlineInputBorder()),
                    items: _entityTypes.map((t) => DropdownMenuItem(value: t['value'], child: Text(t['label']!))).toList(),
                    onChanged: (val) {
                      ref.read(supervisionProvider.notifier).setFilters(entityType: val);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: state.action,
                    decoration: const InputDecoration(labelText: 'Action', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8), border: OutlineInputBorder()),
                    items: _actionTypes.map((t) => DropdownMenuItem(value: t['value'], child: Text(t['label']!))).toList(),
                    onChanged: (val) {
                      ref.read(supervisionProvider.notifier).setFilters(action: val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: state.userId,
              decoration: const InputDecoration(labelText: 'User', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8), border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: '', child: Text('All Users')),
                ...users.map((u) => DropdownMenuItem(value: u.id, child: Text(u.displayName))),
              ],
              onChanged: (val) {
                ref.read(supervisionProvider.notifier).setFilters(userId: val);
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDateFilter(true, state),
                    child: Text(
                      state.dateFrom == null ? 'From Date' : _dateFormatter.format(state.dateFrom!),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDateFilter(false, state),
                    child: Text(
                      state.dateTo == null ? 'To Date' : _dateFormatter.format(state.dateTo!),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                if (state.dateFrom != null || state.dateTo != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(LucideIcons.x, color: AppColors.danger500),
                    onPressed: () {
                      ref.read(supervisionProvider.notifier).setFilters(dateFrom: null, dateTo: null);
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationHeader(SupervisionState state) {
    final startIdx = state.offset + 1;
    final endIdx = (state.offset + state.limit).clamp(0, state.totalCount);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            state.totalCount > 0 ? '$startIdx-$endIdx of ${state.totalCount}' : '0 of 0',
            style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(LucideIcons.chevron_left, size: 20),
                onPressed: state.offset > 0 
                    ? () => ref.read(supervisionProvider.notifier).prevPage()
                    : null,
              ),
              IconButton(
                icon: const Icon(LucideIcons.chevron_right, size: 20),
                onPressed: state.offset + state.limit < state.totalCount
                    ? () => ref.read(supervisionProvider.notifier).nextPage()
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList(List<SupervisionActivity> activities) {
    if (activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.activity, size: 48, color: AppColors.gray400),
            const SizedBox(height: 16),
            Text('No activities matching filters', style: AppTypography.h3),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        return _buildActivityCard(activity);
      },
    );
  }

  Widget _buildActivityCard(SupervisionActivity activity) {
    String finalTime = activity.humanizedTime ?? '';
    if (finalTime.isEmpty) {
      finalTime = DateFormat('MMM d, h:mm a').format(activity.timestamp.toLocal());
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.gray200),
      ),
      color: AppColors.surface,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Action / Entity Icon
            CircleAvatar(
              backgroundColor: activity.actionColor.withOpacity(0.1),
              radius: 18,
              child: Icon(activity.entityIcon, size: 18, color: activity.actionColor),
            ),
            const SizedBox(width: 12),
            // Right Contents
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        activity.userName,
                        style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        finalTime,
                        style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: activity.actionColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          activity.actionDisplay.toUpperCase(),
                          style: TextStyle(
                            color: activity.actionColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        activity.entityType,
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    activity.description,
                    style: AppTypography.body.copyWith(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateFilter(bool isFrom, SupervisionState state) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      if (isFrom) {
        ref.read(supervisionProvider.notifier).setFilters(dateFrom: picked, dateTo: state.dateTo);
      } else {
        ref.read(supervisionProvider.notifier).setFilters(dateFrom: state.dateFrom, dateTo: picked);
      }
    }
  }
}
