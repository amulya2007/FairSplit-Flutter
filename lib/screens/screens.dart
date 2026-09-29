import 'package:flutter/material.dart';

import '../app_state.dart';
import '../app.dart';
import '../models.dart';
import '../theme/app_theme.dart';

const _categories = [
  'Food',
  'Travel',
  'Shopping',
  'Accommodation',
  'Entertainment',
  'Bills',
  'Groceries',
  'Other',
];
const _currencies = {'INR': '₹', 'USD': r'$', 'EUR': '€', 'GBP': '£'};

String money(BuildContext context, int cents, {bool showSign = false}) {
  final state = FairSplitScope.of(context);
  final symbol = _currencies[state.currencyCode] ?? '${state.currencyCode} ';
  final amount = (cents.abs() / 100).toStringAsFixed(2);
  final sign = showSign && cents != 0 ? (cents > 0 ? '+' : '-') : '';
  return '$sign$symbol$amount';
}

String _memberName(FairGroup group, String id) =>
    group.members
        .where((member) => member.id == id)
        .map((member) => member.name)
        .firstOrNull ??
    'Unknown member';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  static const _slides = [
    (
      'Split expenses effortlessly',
      'Add shared costs once. Everyone gets a clear, fair share.',
      Icons.receipt_long_outlined,
    ),
    (
      'Know exactly who owes whom',
      'Balances stay up to date as your group adds expenses.',
      Icons.account_balance_wallet_outlined,
    ),
    (
      'Settle up with less hassle',
      'Get a simple payment plan that keeps transfers to a minimum.',
      Icons.payments_outlined,
    ),
  ];

  Future<void> _finish({bool withSampleData = false}) async {
    final state = FairSplitScope.of(context);
    if (withSampleData) {
      await state.loadDemoData();
    } else {
      await state.clearDemoData();
    }
    await state.completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Skip'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  onPageChanged: (page) => setState(() => _page = page),
                  itemBuilder: (context, index) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 176,
                        height: 176,
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(48),
                        ),
                        child: Icon(
                          _slides[index].$3,
                          size: 72,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(height: 38),
                      Text(
                        _slides[index].$1,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _slides[index].$2,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: index == _page ? 22 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: index == _page
                          ? colors.primary
                          : colors.outlineVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (_page == 2) {
                      _finish();
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                  child: Text(_page == 2 ? 'Start with my own groups' : 'Next'),
                ),
              ),
              if (_page == 2)
                TextButton(
                  onPressed: () => _finish(withSampleData: true),
                  child: const Text('Explore with sample data'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.onOpenGroups,
    required this.onOpenActivity,
    super.key,
  });
  final VoidCallback onOpenGroups;
  final VoidCallback onOpenActivity;

  @override
  Widget build(BuildContext context) {
    final state = FairSplitScope.of(context);
    final colors = Theme.of(context).colorScheme;
    final recent = [...state.expenses]
      ..sort((a, b) => b.date.compareTo(a.date));
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting,',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                  Text(
                    state.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            CircleAvatar(
              backgroundColor: colors.primaryContainer,
              child: Text(
                state.name.isEmpty ? '?' : state.name[0].toUpperCase(),
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall balance',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 5),
                Text(
                  money(context, state.netBalance, showSign: true),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: state.netBalance >= 0
                        ? AppTheme.positive
                        : AppTheme.negative,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _BalanceMetric(
                        label: 'You are owed',
                        cents: state.owedToMe,
                        color: AppTheme.positive,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _BalanceMetric(
                        label: 'You owe',
                        cents: state.iOwe,
                        color: AppTheme.negative,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _SectionTitle(
          title: 'Your groups',
          action: 'See all',
          onTap: onOpenGroups,
        ),
        const SizedBox(height: 12),
        if (state.groups.isEmpty)
          _EmptyState(
            icon: Icons.groups_outlined,
            title: 'No groups yet',
            message: 'Create a group to start sharing expenses.',
            action: 'Create group',
            onPressed: () => _openCreateGroup(context),
          )
        else
          SizedBox(
            height: 125,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: state.groups.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final group = state.groups[index];
                final balance =
                    state.balancesFor(group)[state.currentMemberId] ?? 0;
                return SizedBox(
                  width: 190,
                  child: Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _openGroup(context, group),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _groupIcon(group.category),
                                  size: 19,
                                  color: colors.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    group.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${group.members.length} members',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: colors.onSurfaceVariant),
                            ),
                            Text(
                              balance == 0
                                  ? 'Settled'
                                  : money(context, balance, showSign: true),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: balance >= 0
                                    ? AppTheme.positive
                                    : AppTheme.negative,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 24),
        _SectionTitle(
          title: 'Recent activity',
          action: 'See all',
          onTap: onOpenActivity,
        ),
        const SizedBox(height: 8),
        if (recent.isEmpty)
          _EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No expenses yet',
            message: 'Add a shared expense to start tracking.',
            action: 'Add expense',
            onPressed: () => _openAddExpense(context),
          )
        else
          ...recent.take(5).map((expense) {
            final group = state.groups
                .where((item) => item.id == expense.groupId)
                .firstOrNull;
            if (group == null) return const SizedBox.shrink();
            return _ExpenseTile(
              expense: expense,
              group: group,
              onTap: () => _showExpenseDetails(context, expense, group),
            );
          }),
      ],
    );
  }
}

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = FairSplitScope.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Groups'),
        actions: [
          IconButton(
            tooltip: 'Create group',
            onPressed: () => _openCreateGroup(context),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: state.groups.isEmpty
          ? _EmptyState(
              icon: Icons.groups_outlined,
              title: 'No groups yet',
              message: 'Create your first group to start splitting expenses.',
              action: 'Create group',
              onPressed: () => _openCreateGroup(context),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              itemCount: state.groups.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final group = state.groups[index];
                final balance =
                    state.balancesFor(group)[state.currentMemberId] ?? 0;
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      child: Icon(
                        _groupIcon(group.category),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    title: Text(
                      group.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${group.members.length} members · ${group.category}',
                    ),
                    trailing: Text(
                      balance == 0
                          ? 'Settled'
                          : money(context, balance, showSign: true),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: balance >= 0
                            ? AppTheme.positive
                            : AppTheme.negative,
                      ),
                    ),
                    onTap: () => _openGroup(context, group),
                  ),
                );
              },
            ),
    );
  }
}

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _members = TextEditingController();
  String _category = 'Trip';
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _members.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    try {
      final group = await FairSplitScope.of(context).addGroup(
        groupName: _name.text,
        category: _category,
        description: _description.text,
        memberNames: _members.text.split(','),
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => GroupDetailsScreen(groupId: group.id),
        ),
      );
    } on ArgumentError catch (error) {
      _showMessage(context, error.message.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create group')),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Group name',
              hintText: 'e.g. Goa trip',
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter a group name.'
                : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items:
                const ['Trip', 'Home', 'Friends', 'Family', 'College', 'Other']
                    .map(
                      (item) =>
                          DropdownMenuItem(value: item, child: Text(item)),
                    )
                    .toList(),
            onChanged: (value) => setState(() => _category = value ?? 'Other'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _description,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _members,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Add members',
              hintText: 'Names separated by commas',
              helperText: 'You can invite more people from the group later.',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create group'),
          ),
        ],
      ),
    ),
  );
}

class GroupDetailsScreen extends StatelessWidget {
  const GroupDetailsScreen({required this.groupId, super.key});
  final String groupId;

  @override
  Widget build(BuildContext context) {
    final state = FairSplitScope.of(context);
    final group = state.groups.where((item) => item.id == groupId).firstOrNull;
    if (group == null) {
      return const Scaffold(
        body: Center(child: Text('This group is no longer available.')),
      );
    }
    final balances = state.balancesFor(group);
    final expenses = state.expensesFor(group.id);
    final total = expenses.fold<int>(
      0,
      (sum, expense) => sum + expense.amountCents,
    );
    final yourBalance = balances[state.currentMemberId] ?? 0;
    return Scaffold(
      appBar: AppBar(
        title: Text(group.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Add member',
            onPressed: () => _addMember(context, group),
            icon: const Icon(Icons.person_add_alt_1_outlined),
          ),
          IconButton(
            tooltip: 'Settle up',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SettleUpScreen(groupId: group.id),
              ),
            ),
            icon: const Icon(Icons.payments_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddExpenseScreen(group: group)),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add expense'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          Text(
            '${group.members.length} members · ${group.category}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Group spending',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            money(context, total),
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.account_balance_wallet_outlined,
                color: yourBalance >= 0 ? AppTheme.positive : AppTheme.negative,
              ),
              title: const Text('Your balance'),
              trailing: Text(
                money(context, yourBalance, showSign: true),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: yourBalance >= 0
                      ? AppTheme.positive
                      : AppTheme.negative,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const _SectionTitle(title: 'Members'),
          const SizedBox(height: 8),
          ...group.members.map(
            (member) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: _Avatar(name: member.name),
              title: Text(
                member.id == state.currentMemberId
                    ? '${member.name} (you)'
                    : member.name,
              ),
              trailing: Text(
                money(context, balances[member.id] ?? 0, showSign: true),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: (balances[member.id] ?? 0) >= 0
                      ? AppTheme.positive
                      : AppTheme.negative,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _SectionTitle(
            title: 'Expenses',
            action: expenses.isEmpty ? null : 'Search',
            onTap: expenses.isEmpty ? null : () => _searchGroup(context, group),
          ),
          const SizedBox(height: 8),
          if (expenses.isEmpty)
            _EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No expenses yet',
              message: 'Add a shared expense to start tracking.',
              action: 'Add expense',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddExpenseScreen(group: group),
                ),
              ),
            )
          else
            ...expenses.map(
              (expense) => _ExpenseTile(
                expense: expense,
                group: group,
                onTap: () => _showExpenseDetails(context, expense, group),
              ),
            ),
        ],
      ),
    );
  }
}

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({required this.group, this.existing, super.key});
  final FairGroup group;
  final FairExpense? existing;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.existing?.title);
  late final _amount = TextEditingController(
    text: widget.existing == null
        ? ''
        : (widget.existing!.amountCents / 100).toStringAsFixed(2),
  );
  late final _notes = TextEditingController(text: widget.existing?.notes);
  late final Map<String, TextEditingController> _shareControllers = {
    for (final member in widget.group.members)
      member.id: TextEditingController(text: _initialShare(member.id)),
  };
  final Set<String> _participants = {};
  late String _payer;
  late String _category = widget.existing?.category ?? 'Food';
  late SplitMethod _method = widget.existing?.splitMethod ?? SplitMethod.equal;
  DateTime _date = DateTime.now();
  bool _saving = false;

  String _initialShare(String id) {
    final expense = widget.existing;
    if (expense == null) return '';
    return _methodText(expense.shares[id] ?? 0);
  }

  static String _methodText(int cents) => (cents / 100).toStringAsFixed(2);

  @override
  void initState() {
    super.initState();
    _payer =
        widget.existing?.paidBy ?? FairSplitScope.of(context).currentMemberId;
    _participants.addAll(
      widget.existing?.shares.keys ??
          widget.group.members.map((member) => member.id),
    );
    _amount.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _notes.dispose();
    for (final controller in _shareControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  int? get _amountCents {
    final parsed = double.tryParse(_amount.text.trim().replaceAll(',', '.'));
    if (parsed == null || parsed <= 0 || !parsed.isFinite) return null;
    return (parsed * 100).round();
  }

  Map<String, int> _calculateShares(int total) {
    final selected = widget.group.members
        .where((member) => _participants.contains(member.id))
        .toList();
    if (selected.isEmpty) return {};
    if (_method == SplitMethod.equal) {
      final base = total ~/ selected.length;
      final remainder = total % selected.length;
      return {
        for (var i = 0; i < selected.length; i++)
          selected[i].id: base + (i < remainder ? 1 : 0),
      };
    }
    if (_method == SplitMethod.percentage) {
      final percentages = selected
          .map(
            (member) =>
                double.tryParse(_shareControllers[member.id]!.text) ?? 0,
          )
          .toList();
      final shares = <String, int>{};
      var allocated = 0;
      for (var index = 0; index < selected.length; index++) {
        final cents = index == selected.length - 1
            ? total - allocated
            : (total * percentages[index] / 100).round();
        shares[selected[index].id] = cents;
        allocated += cents;
      }
      return shares;
    }
    return {
      for (final member in selected)
        member.id:
            ((double.tryParse(_shareControllers[member.id]!.text) ?? 0) * 100)
                .round(),
    };
  }

  String? _splitError(int total, Map<String, int> shares) {
    if (_participants.isEmpty) return 'Select at least one participant.';
    if (_method == SplitMethod.percentage) {
      final percentages = widget.group.members
          .where((member) => _participants.contains(member.id))
          .fold<double>(
            0,
            (sum, member) =>
                sum +
                (double.tryParse(_shareControllers[member.id]!.text) ?? -100),
          );
      if ((percentages - 100).abs() > 0.001) {
        return 'Percentages must add up to 100%.';
      }
    }
    if (shares.values.any((share) => share < 0)) {
      return 'Shares cannot be negative.';
    }
    if (shares.values.fold<int>(0, (sum, share) => sum + share) != total) {
      return 'Shares must match the expense amount.';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    final total = _amountCents;
    if (total == null) {
      _showMessage(context, 'Enter an amount greater than zero.');
      return;
    }
    final shares = _calculateShares(total);
    final error = _splitError(total, shares);
    if (error != null) {
      _showMessage(context, error);
      return;
    }
    setState(() => _saving = true);
    final expense = FairExpense(
      id:
          widget.existing?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      groupId: widget.group.id,
      title: _title.text.trim(),
      amountCents: total,
      paidBy: _payer,
      shares: shares,
      splitMethod: _method,
      category: _category,
      date: _date,
      notes: _notes.text.trim(),
    );
    try {
      await FairSplitScope.of(context).saveExpense(expense);
      if (!mounted) return;
      Navigator.pop(context);
      _showMessage(
        context,
        widget.existing == null ? 'Expense added.' : 'Expense updated.',
      );
    } on ArgumentError catch (error) {
      _showMessage(context, error.message.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _amountCents;
    final shares = total == null ? <String, int>{} : _calculateShares(total);
    final splitError = total == null
        ? 'Enter an amount to preview shares.'
        : _splitError(total, shares);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Add expense' : 'Edit expense'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            TextFormField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Expense name',
                hintText: 'e.g. Dinner',
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter an expense name.'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '${_currencySymbol(context)} ',
              ),
              validator: (value) {
                final amount = double.tryParse(
                  (value ?? '').replaceAll(',', '.'),
                );
                return amount == null || amount <= 0
                    ? 'Enter a valid amount.'
                    : null;
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categories
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _category = value ?? 'Other'),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _payer,
              decoration: const InputDecoration(labelText: 'Paid by'),
              items: widget.group.members
                  .map(
                    (member) => DropdownMenuItem(
                      value: member.id,
                      child: Text(
                        member.id == FairSplitScope.of(context).currentMemberId
                            ? '${member.name} (you)'
                            : member.name,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _payer = value ?? _payer),
            ),
            const SizedBox(height: 18),
            const Text(
              'Split between',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            ...widget.group.members.map(
              (member) => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _participants.contains(member.id),
                title: Text(
                  member.id == FairSplitScope.of(context).currentMemberId
                      ? '${member.name} (you)'
                      : member.name,
                ),
                onChanged: (checked) => setState(() {
                  if (checked == true) {
                    _participants.add(member.id);
                  } else {
                    _participants.remove(member.id);
                  }
                }),
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<SplitMethod>(
              segments: const [
                ButtonSegment(value: SplitMethod.equal, label: Text('Equal')),
                ButtonSegment(
                  value: SplitMethod.custom,
                  label: Text('Unequal'),
                ),
                ButtonSegment(value: SplitMethod.percentage, label: Text('%')),
              ],
              selected: {_method},
              onSelectionChanged: (selection) => setState(() {
                _method = selection.first;
                if (_method != SplitMethod.equal) {
                  final people = widget.group.members
                      .where((member) => _participants.contains(member.id))
                      .toList();
                  final defaultValue =
                      _method == SplitMethod.percentage && people.isNotEmpty
                      ? (100 / people.length).toStringAsFixed(2)
                      : '';
                  for (final member in people) {
                    _shareControllers[member.id]!.text = defaultValue;
                  }
                }
              }),
            ),
            if (_method != SplitMethod.equal) ...[
              const SizedBox(height: 8),
              ...widget.group.members
                  .where((member) => _participants.contains(member.id))
                  .map(
                    (member) => Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Expanded(child: Text(member.name)),
                          SizedBox(
                            width: 128,
                            child: TextField(
                              controller: _shareControllers[member.id],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: _method == SplitMethod.custom
                                    ? 'Amount'
                                    : '%',
                                prefixText: _method == SplitMethod.custom
                                    ? '${_currencySymbol(context)} '
                                    : null,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
            const SizedBox(height: 12),
            if (shares.isNotEmpty) ...[
              const Text(
                'Share preview',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              ...widget.group.members
                  .where((member) => shares.containsKey(member.id))
                  .map(
                    (member) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(child: Text(member.name)),
                          Text(money(context, shares[member.id]!)),
                        ],
                      ),
                    ),
                  ),
              if (splitError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    splitError,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Split is balanced',
                    style: TextStyle(color: AppTheme.positive),
                  ),
                ),
            ],
            const SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Date'),
              subtitle: Text(
                MaterialLocalizations.of(context).formatMediumDate(_date),
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            TextFormField(
              controller: _notes,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving || splitError != null ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      widget.existing == null ? 'Add expense' : 'Save changes',
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettleUpScreen extends StatelessWidget {
  const SettleUpScreen({this.groupId, super.key});
  final String? groupId;

  @override
  Widget build(BuildContext context) {
    final state = FairSplitScope.of(context);
    final groups = state.groups.where(
      (group) => groupId == null || group.id == groupId,
    );
    final suggestions = [
      for (final group in groups) ...[
        (group, simplifyDebts(group, state.balancesFor(group))),
      ],
    ];
    final hasPayments = suggestions.any((entry) => entry.$2.isNotEmpty);
    return Scaffold(
      appBar: AppBar(title: const Text('Settle up')),
      body: !hasPayments
          ? const _EmptyState(
              icon: Icons.check_circle_outline,
              title: 'All settled up',
              message: 'There are no outstanding group balances.',
              action: null,
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Suggested to minimize the number of payments.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                for (final entry in suggestions)
                  for (final payment in entry.$2)
                    Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          '${payment.payer.name} → ${payment.payee.name}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(entry.$1.name),
                        trailing: Text(
                          money(context, payment.amountCents),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        onTap: () =>
                            _confirmSettlement(context, entry.$1, payment),
                      ),
                    ),
              ],
            ),
    );
  }
}

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  String _filter = 'All';
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final state = FairSplitScope.of(context);
    final entries = <_ActivityEntry>[
      for (final expense in state.expenses)
        _ActivityEntry(
          expense.date,
          'Expense',
          expense.title,
          expense.groupId,
          expense.amountCents,
          expense.paidBy,
          expense.id,
        ),
      for (final settlement in state.settlements)
        _ActivityEntry(
          settlement.date,
          'Settlement',
          'Settlement recorded',
          settlement.groupId,
          settlement.amountCents,
          settlement.paidBy,
          settlement.id,
        ),
    ]..sort((a, b) => b.date.compareTo(a.date));
    final filtered = entries.where((entry) {
      final group = state.groups
          .where((item) => item.id == entry.groupId)
          .firstOrNull;
      final typeMatches = _filter == 'All' || entry.type == _filter;
      final query = _query.toLowerCase();
      final queryMatches =
          query.isEmpty ||
          entry.title.toLowerCase().contains(query) ||
          (group?.name.toLowerCase().contains(query) ?? false) ||
          _memberName(
            group ??
                const FairGroup(id: '', name: '', category: '', members: []),
            entry.memberId,
          ).toLowerCase().contains(query);
      return typeMatches && queryMatches;
    }).toList();
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Activity')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search expenses or groups',
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'All', label: Text('All')),
                ButtonSegment(value: 'Expense', label: Text('Expenses')),
                ButtonSegment(value: 'Settlement', label: Text('Settlements')),
              ],
              selected: {_filter},
              onSelectionChanged: (value) =>
                  setState(() => _filter = value.first),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? const _EmptyState(
                    icon: Icons.history,
                    title: 'Nothing to show',
                    message: 'New expenses and settlements will appear here.',
                    action: null,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(indent: 56),
                    itemBuilder: (context, index) {
                      final entry = filtered[index];
                      final group = state.groups
                          .where((item) => item.id == entry.groupId)
                          .firstOrNull;
                      if (group == null) return const SizedBox.shrink();
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          child: Icon(
                            entry.type == 'Expense'
                                ? Icons.receipt_long_outlined
                                : Icons.payments_outlined,
                          ),
                        ),
                        title: Text(entry.title),
                        subtitle: Text(
                          '${group.name} · ${_memberName(group, entry.memberId)} · ${MaterialLocalizations.of(context).formatMediumDate(entry.date)}',
                        ),
                        trailing: Text(
                          money(context, entry.amount),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        onTap: entry.type == 'Expense'
                            ? () {
                                final expense = state.expenses
                                    .where((item) => item.id == entry.id)
                                    .firstOrNull;
                                if (expense != null) {
                                  _showExpenseDetails(context, expense, group);
                                }
                              }
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = FairSplitScope.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: _Avatar(name: state.name, radius: 26),
              title: Text(
                state.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(state.email),
              trailing: IconButton(
                tooltip: 'Edit profile',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _editProfile(context),
              ),
            ),
          ),
          const SizedBox(height: 22),
          const _SectionTitle(title: 'Preferences'),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.currency_exchange),
                  title: const Text('Currency'),
                  trailing: DropdownButton<String>(
                    value: state.currencyCode,
                    underline: const SizedBox.shrink(),
                    items: _currencies.keys
                        .map(
                          (code) =>
                              DropdownMenuItem(value: code, child: Text(code)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) state.setCurrency(value);
                    },
                  ),
                ),
                const Divider(indent: 56),
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Dark theme'),
                  value: state.darkMode,
                  onChanged: state.setDarkMode,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const _SectionTitle(title: 'Your spending this month'),
          const SizedBox(height: 8),
          _Insights(state: state),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => _clearDemoData(context),
            icon: const Icon(Icons.delete_sweep_outlined),
            label: const Text('Remove sample data'),
          ),
          const SizedBox(height: 18),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('FairSplit'),
            subtitle: const Text('Smart group expense sharing'),
          ),
        ],
      ),
    );
  }
}

Future<void> _clearDemoData(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Remove sample data?'),
      content: const Text(
        'Only the original sample expenses will be removed. Any groups with your own expenses will stay.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Keep sample data'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Remove'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  await FairSplitScope.of(context).clearDemoData();
  if (context.mounted) _showMessage(context, 'Sample data removed.');
}

class _Insights extends StatelessWidget {
  const _Insights({required this.state});
  final FairSplitState state;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthly = state.expenses
        .where(
          (expense) =>
              expense.date.year == now.year && expense.date.month == now.month,
        )
        .toList();
    final spent = monthly.fold<int>(
      0,
      (sum, expense) => sum + expense.amountCents,
    );
    final paid = monthly
        .where((expense) => expense.paidBy == state.currentMemberId)
        .fold<int>(0, (sum, expense) => sum + expense.amountCents);
    final share = monthly.fold<int>(
      0,
      (sum, expense) => sum + (expense.shares[state.currentMemberId] ?? 0),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _InsightRow(label: 'Shared spending', value: money(context, spent)),
            const Divider(height: 20),
            _InsightRow(label: 'You paid', value: money(context, paid)),
            const Divider(height: 20),
            _InsightRow(label: 'Your share', value: money(context, share)),
          ],
        ),
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(label)),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
    ],
  );
}

class _BalanceMetric extends StatelessWidget {
  const _BalanceMetric({
    required this.label,
    required this.cents,
    required this.color,
  });
  final String label;
  final int cents;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        money(context, cents),
        style: TextStyle(fontWeight: FontWeight.w700, color: color),
      ),
    ],
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.action, this.onTap});
  final String title;
  final String? action;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      if (action != null) TextButton(onPressed: onTap, child: Text(action!)),
    ],
  );
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({
    required this.expense,
    required this.group,
    required this.onTap,
  });
  final FairExpense expense;
  final FairGroup group;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: CircleAvatar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Icon(_categoryIcon(expense.category)),
    ),
    title: Text(
      expense.title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontWeight: FontWeight.w600),
    ),
    subtitle: Text(
      '${group.name} · ${_memberName(group, expense.paidBy)} paid',
    ),
    trailing: Text(
      money(context, expense.amountCents),
      style: const TextStyle(fontWeight: FontWeight.w600),
    ),
    onTap: onTap,
  );
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.radius = 20});
  final String name;
  final double radius;
  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: radius,
    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
    child: Text(
      name.isEmpty ? '?' : name[0].toUpperCase(),
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.onPressed,
  });
  final IconData icon;
  final String title;
  final String message;
  final String? action;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 38, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: onPressed, child: Text(action!)),
          ],
        ],
      ),
    ),
  );
}

class _ActivityEntry {
  const _ActivityEntry(
    this.date,
    this.type,
    this.title,
    this.groupId,
    this.amount,
    this.memberId,
    this.id,
  );
  final DateTime date;
  final String type;
  final String title;
  final String groupId;
  final int amount;
  final String memberId;
  final String id;
}

void _openCreateGroup(BuildContext context) => Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
);
void _openGroup(BuildContext context, FairGroup group) => Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => GroupDetailsScreen(groupId: group.id)),
);

void _openAddExpense(BuildContext context) {
  final groups = FairSplitScope.of(context).groups;
  if (groups.isEmpty) {
    _openCreateGroup(context);
    return;
  }
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => AddExpenseScreen(group: groups.first)),
  );
}

IconData _groupIcon(String category) => switch (category) {
  'Trip' => Icons.luggage_outlined,
  'Home' => Icons.home_outlined,
  'Friends' => Icons.people_outline,
  'Family' => Icons.family_restroom_outlined,
  'College' => Icons.school_outlined,
  _ => Icons.groups_outlined,
};

IconData _categoryIcon(String category) => switch (category) {
  'Food' => Icons.restaurant_outlined,
  'Travel' => Icons.directions_car_outlined,
  'Shopping' => Icons.shopping_bag_outlined,
  'Accommodation' => Icons.hotel_outlined,
  'Entertainment' => Icons.local_activity_outlined,
  'Bills' => Icons.receipt_outlined,
  'Groceries' => Icons.local_grocery_store_outlined,
  _ => Icons.receipt_long_outlined,
};

String _currencySymbol(BuildContext context) =>
    _currencies[FairSplitScope.of(context).currencyCode] ??
    '${FairSplitScope.of(context).currencyCode} ';

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<void> _addMember(BuildContext context, FairGroup group) async {
  final controller = TextEditingController();
  final name = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Add member'),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(labelText: 'Name'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('Add'),
        ),
      ],
    ),
  );
  controller.dispose();
  if (name == null || !context.mounted) return;
  try {
    await FairSplitScope.of(context).addMember(group.id, name);
  } on ArgumentError catch (error) {
    if (context.mounted) _showMessage(context, error.message.toString());
  }
}

Future<void> _searchGroup(BuildContext context, FairGroup group) async {
  final query = await showSearch<String>(
    context: context,
    delegate: _ExpenseSearchDelegate(group),
  );
  if (query == null || !context.mounted) return;
  final expense = FairSplitScope.of(context)
      .expensesFor(group.id)
      .where((item) => item.title.toLowerCase().contains(query.toLowerCase()))
      .firstOrNull;
  if (expense != null && context.mounted) {
    _showExpenseDetails(context, expense, group);
  }
}

class _ExpenseSearchDelegate extends SearchDelegate<String> {
  _ExpenseSearchDelegate(this.group);
  final FairGroup group;
  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];
  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, ''),
  );
  @override
  Widget buildResults(BuildContext context) => _results(context);
  @override
  Widget buildSuggestions(BuildContext context) => _results(context);
  Widget _results(BuildContext context) {
    final expenses = FairSplitScope.of(context)
        .expensesFor(group.id)
        .where((item) => item.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return ListView(
      children: [
        for (final expense in expenses)
          ListTile(
            title: Text(expense.title),
            subtitle: Text(expense.category),
            trailing: Text(money(context, expense.amountCents)),
            onTap: () => close(context, expense.title),
          ),
      ],
    );
  }
}

Future<void> _showExpenseDetails(
  BuildContext context,
  FairExpense expense,
  FairGroup group,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      final state = FairSplitScope.of(context);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                expense.title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                money(context, expense.amountCents),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${expense.category} · ${MaterialLocalizations.of(context).formatMediumDate(expense.date)}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              Text('Paid by ${_memberName(group, expense.paidBy)}'),
              const SizedBox(height: 10),
              for (final entry in expense.shares.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Expanded(child: Text(_memberName(group, entry.key))),
                      Text(money(context, entry.value)),
                    ],
                  ),
                ),
              if (expense.notes.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(expense.notes),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddExpenseScreen(
                              group: group,
                              existing: expense,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete expense?'),
                            content: const Text(
                              'This will update everyone’s group balances.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await state.deleteExpense(expense.id);
                          if (context.mounted) {
                            Navigator.pop(context);
                            _showMessage(context, 'Expense deleted.');
                          }
                        }
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _confirmSettlement(
  BuildContext context,
  FairGroup group,
  SuggestedPayment payment,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Record settlement?'),
      content: Text(
        '${payment.payer.name} paid ${payment.payee.name} ${money(context, payment.amountCents)}.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Mark as paid'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  try {
    await FairSplitScope.of(context).recordSettlement(
      FairSettlement(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        groupId: group.id,
        paidBy: payment.payer.id,
        paidTo: payment.payee.id,
        amountCents: payment.amountCents,
        date: DateTime.now(),
      ),
    );
    if (context.mounted) _showMessage(context, 'Settlement recorded.');
  } on ArgumentError catch (error) {
    if (context.mounted) _showMessage(context, error.message.toString());
  }
}

Future<void> _editProfile(BuildContext context) async {
  final state = FairSplitScope.of(context);
  final name = TextEditingController(text: state.name);
  final email = TextEditingController(text: state.email);
  final result = await showDialog<(String, String)>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Edit profile'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, (name.text, email.text)),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  name.dispose();
  email.dispose();
  if (result == null || !context.mounted) return;
  try {
    await state.updateProfile(name: result.$1, email: result.$2);
  } on ArgumentError catch (error) {
    if (context.mounted) _showMessage(context, error.message.toString());
  }
}
