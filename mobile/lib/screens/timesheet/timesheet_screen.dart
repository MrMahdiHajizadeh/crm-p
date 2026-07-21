import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../core/theme/theme.dart';
import '../../data/models/timesheet.dart';
import '../../data/models/lookup_models.dart';
import '../../providers/timesheet_provider.dart';
import '../../providers/lookup_provider.dart';
import '../../providers/auth_provider.dart';
class TimesheetScreen extends ConsumerStatefulWidget {
  const TimesheetScreen({super.key});

  @override
  ConsumerState<TimesheetScreen> createState() => _TimesheetScreenState();
}

class _TimesheetScreenState extends ConsumerState<TimesheetScreen> {
  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd');

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timesheetProvider);
    final authState = ref.watch(authProvider);
    
    // Check if the current user has admin rights. 
    // In our authentication structure, the organization details have the role.
    final isAdmin = authState.selectedOrganization?.role == 'ADMIN';

    final usersList = ref.watch(usersProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceDim,
      appBar: AppBar(
        title: const Text('Timesheet'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevron_left),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refresh_cw),
            onPressed: () => ref.read(timesheetProvider.notifier).load(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar
          _buildFilterBar(state, isAdmin, usersList),
          
          // Presets
          _buildPresetsBar(),

          // Summary Section
          if (state.summary != null) _buildSummaryBar(state.summary!),

          // Content
          Expanded(
            child: state.isLoading && state.summary == null
                ? const Center(child: CircularProgressIndicator())
                : state.errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.triangle_alert, size: 48, color: AppColors.danger500),
                            const SizedBox(height: 16),
                            Text(state.errorMessage!, style: AppTypography.body),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => ref.read(timesheetProvider.notifier).load(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _buildDaysList(state.summary?.days ?? []),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(TimesheetState state, bool isAdmin, List<UserLookup> users) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(LucideIcons.calendar, size: 16),
                  label: Text(
                    '${_dateFormatter.format(state.startDate)} to ${_dateFormatter.format(state.endDate)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () => _pickDateRange(state),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(LucideIcons.chevron_left),
                onPressed: () => ref.read(timesheetProvider.notifier).shiftWeek(-7),
              ),
              IconButton(
                icon: const Icon(LucideIcons.chevron_right),
                onPressed: () => ref.read(timesheetProvider.notifier).shiftWeek(7),
              ),
            ],
          ),
          if (isAdmin) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(LucideIcons.user, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: state.profileFilter,
                      items: [
                        const DropdownMenuItem(value: '', child: Text('Filter: My Timesheet')),
                        ...users.map((u) => DropdownMenuItem(
                          value: u.id,
                          child: Text('Filter: ${u.displayName} (${u.email})'),
                        )),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(timesheetProvider.notifier).setProfileFilter(val);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPresetsBar() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            _buildPresetButton('This Week', () => _applyPreset('this-week')),
            _buildPresetButton('Last Week', () => _applyPreset('last-week')),
            _buildPresetButton('Last 7d', () => _applyPreset('last-7')),
            _buildPresetButton('Last 30d', () => _applyPreset('last-30')),
            _buildPresetButton('This Month', () => _applyPreset('this-month')),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetButton(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(label, style: const TextStyle(fontSize: 10)),
      ),
    );
  }

  Widget _buildSummaryBar(TimesheetSummary summary) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Total Time', _formatMinutes(summary.totalMinutes)),
          _buildSummaryItem('Billable Time', _formatMinutes(summary.billableMinutes)),
          if (summary.runningCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.success200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: AppColors.success500, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${summary.runningCount} Running',
                    style: AppTypography.caption.copyWith(color: AppColors.success700, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(value, style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDaysList(List<TimesheetDay> days) {
    if (days.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.clock, size: 48, color: AppColors.gray400),
            const SizedBox(height: 16),
            Text('No time entries found', style: AppTypography.h3),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        return _buildDaySection(day);
      },
    );
  }

  Widget _buildDaySection(TimesheetDay day) {
    // Parse day date to format nicely
    String formattedDate = day.date;
    try {
      final date = DateTime.parse(day.date);
      formattedDate = DateFormat('EEEE, MMM d').format(date);
    } catch (_) {}

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(formattedDate, style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
              Text(_formatMinutes(day.totalMinutes), style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        if (day.entries.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('No entries logged.', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: AppColors.textTertiary)),
          )
        else
          ...day.entries.map((e) => _buildEntryCard(e)),
      ],
    );
  }

  Widget _buildEntryCard(TimesheetEntry entry) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: entry.isRunning ? AppColors.success300 : AppColors.gray200,
        ),
      ),
      color: entry.isRunning ? AppColors.success50.withOpacity(0.5) : AppColors.surface,
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            Expanded(
              child: Text(
                entry.description ?? 'Untitled Time Session',
                style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              _formatMinutes(entry.durationMinutes),
              style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(LucideIcons.calendar, size: 12, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  DateFormat('h:mm a').format(entry.startedAt.toLocal()),
                  style: AppTypography.caption,
                ),
                const SizedBox(width: 12),
                if (entry.billable)
                  _buildBadge('Billable', AppColors.success50, AppColors.success600),
                if (entry.invoiceId != null) ...[
                  const SizedBox(width: 6),
                  _buildBadge('Invoiced', AppColors.primary50, AppColors.primary600),
                ],
                if (entry.isRunning) ...[
                  const SizedBox(width: 6),
                  _buildBadge('Running', AppColors.success50, AppColors.success500),
                ],
              ],
            ),
          ],
        ),
        trailing: entry.isRunning
            ? IconButton(
                icon: Icon(LucideIcons.ban, color: AppColors.danger500),
                onPressed: () => _stopTimer(entry.id),
                tooltip: 'Stop Timer',
              )
            : entry.caseId != null
                ? IconButton(
                    icon: const Icon(LucideIcons.external_link, size: 16, color: AppColors.textTertiary),
                    onPressed: () => context.push('/tickets/${entry.caseId}'),
                    tooltip: 'Go to Ticket',
                  )
                : null,
      ),
    );
  }

  Widget _buildBadge(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: textColor, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _pickDateRange(TimesheetState state) async {
    final range = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: state.startDate, end: state.endDate),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (range != null) {
      ref.read(timesheetProvider.notifier).setDateRange(range.start, range.end);
    }
  }

  void _applyPreset(String preset) {
    final now = DateTime.now();
    DateTime start = now;
    DateTime end = now;

    monOf(DateTime base) {
      final dow = base.weekday;
      return base.subtract(Duration(days: dow - 1));
    }

    if (preset == 'this-week') {
      start = monOf(now);
      end = start.add(const Duration(days: 6));
    } else if (preset == 'last-week') {
      start = monOf(now).subtract(const Duration(days: 7));
      end = start.add(const Duration(days: 6));
    } else if (preset == 'last-7') {
      start = now.subtract(const Duration(days: 6));
      end = now;
    } else if (preset == 'last-30') {
      start = now.subtract(const Duration(days: 29));
      end = now;
    } else if (preset == 'this-month') {
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month + 1, 0);
    }

    ref.read(timesheetProvider.notifier).setDateRange(start, end);
  }

  String _formatMinutes(int minutes) {
    if (minutes <= 0) return '0m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  Future<void> _stopTimer(String id) async {
    final success = await ref.read(timesheetProvider.notifier).stopTimer(id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Timer stopped.')),
      );
    }
  }
}
