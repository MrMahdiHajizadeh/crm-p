import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../core/theme/theme.dart';
import '../../data/models/goal.dart';
import '../../data/models/lookup_models.dart';
import '../../providers/goals_provider.dart';
import '../../providers/lookup_provider.dart';
import '../../widgets/common/common.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(goalsProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceDim,
      appBar: AppBar(
        title: const Text('Goals & Leaderboard'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevron_left),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary600,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary600,
          tabs: const [
            Tab(text: 'Goals', icon: Icon(LucideIcons.target, size: 18)),
            Tab(text: 'Leaderboard', icon: Icon(LucideIcons.trophy, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGoalsTab(state),
          _buildLeaderboardTab(state),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showGoalForm(),
        backgroundColor: AppColors.primary600,
        foregroundColor: Colors.white,
        child: const Icon(LucideIcons.plus),
      ),
    );
  }

  Widget _buildGoalsTab(GoalsState state) {
    return Column(
      children: [
        // Search & Filter
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search goals...',
                    prefixIcon: const Icon(LucideIcons.search, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                  onSubmitted: (val) {
                    ref.read(goalsProvider.notifier).setFilters(search: val);
                  },
                ),
              ),
            ],
          ),
        ),

        // Status filter row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              _buildFilterChip('All', 'all', state.status),
              _buildFilterChip('On Track', 'on_track', state.status),
              _buildFilterChip('At Risk', 'at_risk', state.status),
              _buildFilterChip('Behind', 'behind', state.status),
              _buildFilterChip('Completed', 'completed', state.status),
            ],
          ),
        ),

        const SizedBox(height: 8),

        Expanded(
          child: state.isLoading && state.goals.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : state.goals.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.target, size: 48, color: AppColors.gray400),
                          const SizedBox(height: 16),
                          Text('No goals found', style: AppTypography.h3),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref.read(goalsProvider.notifier).load(),
                      child: ListView.builder(
                        itemCount: state.goals.length,
                        itemBuilder: (context, index) {
                          final goal = state.goals[index];
                          return _buildGoalCard(goal);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, String currentValue) {
    final isSelected = value == currentValue;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.primary100,
        checkmarkColor: AppColors.primary600,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary700 : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        onSelected: (selected) {
          if (selected) {
            ref.read(goalsProvider.notifier).setFilters(status: value);
          }
        },
      ),
    );
  }

  Widget _buildGoalCard(Goal goal) {
    final numberFormat = NumberFormat.compact();
    final isRevenue = goal.goalType == GoalType.revenue;
    final currencySymbol = isRevenue ? '\$' : '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.gray200),
      ),
      color: AppColors.surface,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    goal.name,
                    style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: goal.status.bgColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    goal.status.label,
                    style: AppTypography.caption.copyWith(
                      color: goal.status.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    goal.goalType.label,
                    style: AppTypography.caption.copyWith(fontSize: 10, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${goal.periodType.label} Period',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$currencySymbol${numberFormat.format(goal.progressValue)} / $currencySymbol${numberFormat.format(goal.targetValue)}',
                  style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${goal.progressPercent.toStringAsFixed(0)}%',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: goal.progressPercent >= 100 ? AppColors.success600 : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (goal.progressPercent / 100).clamp(0.0, 1.0),
                backgroundColor: AppColors.gray200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  goal.progressPercent >= 100 ? AppColors.success500 : goal.status.color,
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (goal.assignedTo != null) ...[
                  const Icon(LucideIcons.user, size: 12, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    goal.assignedTo!.name,
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ] else if (goal.team != null) ...[
                  const Icon(LucideIcons.users, size: 12, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    goal.team!.name,
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ],
                const Spacer(),
                IconButton(
                  icon: Icon(LucideIcons.pen, size: 16, color: AppColors.primary500),
                  onPressed: () => _showGoalForm(goal: goal),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(LucideIcons.trash_2, size: 16, color: AppColors.danger500),
                  onPressed: () => _confirmDeleteGoal(goal.id),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardTab(GoalsState state) {
    return Column(
      children: [
        // Leaderboard Period Selector
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Team Standings', style: AppTypography.h3),
              DropdownButton<String>(
                value: state.leaderboardPeriod,
                items: const [
                  DropdownMenuItem(value: 'MONTHLY', child: Text('Monthly')),
                  DropdownMenuItem(value: 'QUARTERLY', child: Text('Quarterly')),
                  DropdownMenuItem(value: 'YEARLY', child: Text('Yearly')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    ref.read(goalsProvider.notifier).setLeaderboardPeriod(val);
                  }
                },
              ),
            ],
          ),
        ),

        Expanded(
          child: state.isLoading && state.leaderboard.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : state.leaderboard.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.trophy, size: 48, color: AppColors.gray400),
                          const SizedBox(height: 16),
                          Text('No data for this period', style: AppTypography.h3),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: state.leaderboard.length,
                      itemBuilder: (context, index) {
                        final entry = state.leaderboard[index];
                        return _buildLeaderboardCard(entry);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardCard(LeaderboardEntry entry) {
    Color rankColor = AppColors.textSecondary;
    if (entry.rank == 1) rankColor = Colors.amber;
    if (entry.rank == 2) rankColor = Colors.grey;
    if (entry.rank == 3) rankColor = Colors.brown;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.gray200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: rankColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  entry.rank.toString(),
                  style: TextStyle(color: rankColor, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.user,
                    style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    entry.goalName,
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${entry.percent.toStringAsFixed(0)}%',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: entry.percent >= 100 ? AppColors.success600 : AppColors.primary600,
                  ),
                ),
                Text(
                  '${entry.achieved.toStringAsFixed(0)} / ${entry.target.toStringAsFixed(0)}',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteGoal(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: const Text('Are you sure you want to delete this sales goal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref.read(goalsProvider.notifier).deleteGoal(id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Goal deleted successfully')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.danger600)),
          ),
        ],
      ),
    );
  }

  void _showGoalForm({Goal? goal}) {
    showDialog(
      context: context,
      builder: (context) => _GoalFormDialog(
        goal: goal,
        onSuccess: () => ref.read(goalsProvider.notifier).load(),
      ),
    );
  }
}

class _GoalFormDialog extends ConsumerStatefulWidget {
  final Goal? goal;
  final VoidCallback onSuccess;

  const _GoalFormDialog({this.goal, required this.onSuccess});

  @override
  ConsumerState<_GoalFormDialog> createState() => _GoalFormDialogState();
}

class _GoalFormDialogState extends ConsumerState<_GoalFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();

  GoalType _type = GoalType.revenue;
  PeriodType _period = PeriodType.monthly;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _assignedToId;
  String? _teamId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      _nameController.text = widget.goal!.name;
      _targetController.text = widget.goal!.targetValue.toString();
      _type = widget.goal!.goalType;
      _period = widget.goal!.periodType;
      _startDate = widget.goal!.periodStart;
      _endDate = widget.goal!.periodEnd;
      _assignedToId = widget.goal!.assignedToId;
      _teamId = widget.goal!.teamId;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeUsers = ref.watch(usersProvider);
    final teams = ref.watch(teamsProvider);

    return AlertDialog(
      title: Text(widget.goal == null ? 'Create Sales Goal' : 'Edit Goal', style: AppTypography.h3),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Goal Name', border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<GoalType>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Goal Type', border: OutlineInputBorder()),
                items: GoalType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _type = val);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _targetController,
                decoration: const InputDecoration(labelText: 'Target Value', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (val) => val == null || val.isEmpty ? 'Target is required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<PeriodType>(
                value: _period,
                decoration: const InputDecoration(labelText: 'Period', border: OutlineInputBorder()),
                items: PeriodType.values.map((p) => DropdownMenuItem(value: p, child: Text(p.label))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _period = val);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Start Date', style: TextStyle(fontSize: 12)),
                      subtitle: Text(_startDate == null ? 'Not set' : DateFormat('yyyy-MM-dd').format(_startDate!)),
                      trailing: IconButton(
                        icon: const Icon(LucideIcons.calendar, size: 18),
                        onPressed: () => _pickDate(true),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('End Date', style: TextStyle(fontSize: 12)),
                      subtitle: Text(_endDate == null ? 'Not set' : DateFormat('yyyy-MM-dd').format(_endDate!)),
                      trailing: IconButton(
                        icon: const Icon(LucideIcons.calendar, size: 18),
                        onPressed: () => _pickDate(false),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _assignedToId,
                decoration: const InputDecoration(labelText: 'Assignee', border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Unassigned')),
                  ...activeUsers.map((u) => DropdownMenuItem(value: u.id, child: Text(u.displayName))),
                ],
                onChanged: (val) {
                  setState(() {
                    _assignedToId = val;
                    if (val != null) _teamId = null; // mutually exclusive per-assignee/team
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _teamId,
                decoration: const InputDecoration(labelText: 'Assign Team', border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem(value: null, child: Text('No Team')),
                  ...teams.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))),
                ],
                onChanged: (val) {
                  setState(() {
                    _teamId = val;
                    if (val != null) _assignedToId = null; // mutually exclusive per-assignee/team
                  });
                },
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
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary600, foregroundColor: Colors.white),
          child: _submitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _pickDate(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        if (isStart) {
          _startDate = date;
        } else {
          _endDate = date;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    
    final payload = {
      'name': _nameController.text,
      'goal_type': _type.value,
      'target_value': double.parse(_targetController.text),
      'period_type': _period.value,
      'period_start': _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : null,
      'period_end': _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null,
      'assigned_to': _assignedToId,
      'team': _teamId,
    };

    bool success;
    if (widget.goal == null) {
      success = await ref.read(goalsProvider.notifier).createGoal(payload);
    } else {
      success = await ref.read(goalsProvider.notifier).updateGoal(widget.goal!.id, payload);
    }

    setState(() => _submitting = false);
    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      widget.onSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.goal == null ? 'Goal created' : 'Goal updated')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Operation failed')),
      );
    }
  }
}
