import 'package:flutter/material.dart';

import 'app_state.dart';
import 'screens/screens.dart';
import 'theme/app_theme.dart';

class FairSplitBootstrap extends StatefulWidget {
  const FairSplitBootstrap({super.key});

  @override
  State<FairSplitBootstrap> createState() => _FairSplitBootstrapState();
}

class _FairSplitBootstrapState extends State<FairSplitBootstrap> {
  late final Future<FairSplitState> _state = FairSplitState.create();

  @override
  Widget build(BuildContext context) => FutureBuilder<FairSplitState>(
    future: _state,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_outlined, size: 42),
                    const SizedBox(height: 12),
                    const Text('FairSplit could not open local data.'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
      if (!snapshot.hasData) {
        return MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        );
      }
      return FairSplitApp(state: snapshot.requireData);
    },
  );
}

class FairSplitApp extends StatelessWidget {
  const FairSplitApp({required this.state, super.key});

  final FairSplitState state;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: state,
    builder: (context, _) => MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FairSplit',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: state.darkMode ? ThemeMode.dark : ThemeMode.light,
      home: state.onboardingComplete
          ? const MainNavigation()
          : const OnboardingScreen(),
      builder: (context, child) =>
          FairSplitScope(state: state, child: child ?? const SizedBox.shrink()),
    ),
  );
}

class FairSplitScope extends InheritedWidget {
  const FairSplitScope({required this.state, required super.child, super.key});

  final FairSplitState state;

  static FairSplitState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FairSplitScope>()!.state;

  @override
  bool updateShouldNotify(FairSplitScope oldWidget) => state != oldWidget.state;
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onOpenGroups: () => setState(() => _index = 1)),
      const GroupsScreen(),
      const ActivityScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _index, children: pages),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add to FairSplit',
        onPressed: _showQuickActions,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Groups',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _showQuickActions() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Text(
                'Quick add',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Add expense'),
              onTap: () {
                Navigator.pop(context);
                _chooseExpenseGroup();
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_add_outlined),
              title: const Text('Create group'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.payments_outlined),
              title: const Text('Settle up'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettleUpScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _chooseExpenseGroup() {
    final groups = FairSplitScope.of(context).groups;
    if (groups.isEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text(
                'Choose a group',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            for (final group in groups)
              ListTile(
                leading: const Icon(Icons.groups_outlined),
                title: Text(group.name),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddExpenseScreen(group: group),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
