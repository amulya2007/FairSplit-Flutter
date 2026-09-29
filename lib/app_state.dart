import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import 'models.dart';

class FairSplitState extends ChangeNotifier {
  FairSplitState._(this._database);

  final Database _database;
  List<FairGroup> groups = [];
  List<FairExpense> expenses = [];
  List<FairSettlement> settlements = [];
  String currentMemberId = 'amulya';
  String name = 'Amulya';
  String email = 'amulya@example.com';
  String currencyCode = 'INR';
  bool darkMode = false;
  bool onboardingComplete = false;

  FairMember get currentMember =>
      FairMember(id: currentMemberId, name: name, email: email);

  static Future<FairSplitState> create() async {
    final databasePath = path.join(await getDatabasesPath(), 'fairsplit.db');
    final database = await openDatabase(
      databasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE groups (id TEXT PRIMARY KEY, payload TEXT NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE expenses (id TEXT PRIMARY KEY, payload TEXT NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE settlements (id TEXT PRIMARY KEY, payload TEXT NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE preferences (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
        );
      },
    );
    final state = FairSplitState._(database);
    await state._load();
    return state;
  }

  Future<void> _load() async {
    final groupRows = await _database.query('groups');
    final expenseRows = await _database.query('expenses');
    final settlementRows = await _database.query('settlements');
    final preferenceRows = await _database.query('preferences');
    groups = groupRows
        .map(
          (row) => FairGroup.fromJson(
            jsonDecode(row['payload']! as String) as Map<String, dynamic>,
          ),
        )
        .toList();
    expenses = expenseRows
        .map(
          (row) => FairExpense.fromJson(
            jsonDecode(row['payload']! as String) as Map<String, dynamic>,
          ),
        )
        .toList();
    settlements = settlementRows
        .map(
          (row) => FairSettlement.fromJson(
            jsonDecode(row['payload']! as String) as Map<String, dynamic>,
          ),
        )
        .toList();

    final preferences = {
      for (final row in preferenceRows)
        row['key']! as String: row['value']! as String,
    };
    currentMemberId = preferences['memberId'] ?? currentMemberId;
    name = preferences['name'] ?? name;
    email = preferences['email'] ?? email;
    currencyCode = preferences['currency'] ?? currencyCode;
    darkMode = preferences['darkMode'] == 'true';
    onboardingComplete = preferences['onboardingComplete'] == 'true';

    if (groups.isEmpty) await _seedDemoData();
  }

  Future<void> _seedDemoData() async {
    final members = [
      currentMember,
      const FairMember(id: 'rahul', name: 'Rahul'),
      const FairMember(id: 'priya', name: 'Priya'),
      const FairMember(id: 'anu', name: 'Anu'),
    ];
    final goa = FairGroup(
      id: 'goa-trip',
      name: 'Goa Trip',
      category: 'Trip',
      members: members,
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
    );
    final apartment = FairGroup(
      id: 'apartment',
      name: 'Apartment',
      category: 'Home',
      members: [members[0], members[1], members[2]],
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    );
    final now = DateTime.now();
    groups = [goa, apartment];
    expenses = [
      FairExpense(
        id: 'demo-dinner',
        groupId: goa.id,
        title: 'Dinner by the beach',
        amountCents: 120000,
        paidBy: currentMemberId,
        shares: {for (final member in members) member.id: 30000},
        splitMethod: SplitMethod.equal,
        category: 'Food',
        date: now.subtract(const Duration(days: 1)),
      ),
      FairExpense(
        id: 'demo-cab',
        groupId: goa.id,
        title: 'Airport cab',
        amountCents: 45000,
        paidBy: 'rahul',
        shares: const {'amulya': 15000, 'rahul': 15000, 'priya': 15000},
        splitMethod: SplitMethod.equal,
        category: 'Travel',
        date: now.subtract(const Duration(hours: 15)),
      ),
      FairExpense(
        id: 'demo-hotel',
        groupId: goa.id,
        title: 'Guesthouse',
        amountCents: 320000,
        paidBy: 'priya',
        shares: {for (final member in members) member.id: 80000},
        splitMethod: SplitMethod.equal,
        category: 'Accommodation',
        date: now.subtract(const Duration(days: 2)),
      ),
      FairExpense(
        id: 'demo-groceries',
        groupId: apartment.id,
        title: 'Weekly groceries',
        amountCents: 85000,
        paidBy: currentMemberId,
        shares: const {'amulya': 28334, 'rahul': 28333, 'priya': 28333},
        splitMethod: SplitMethod.equal,
        category: 'Groceries',
        date: now.subtract(const Duration(days: 3)),
      ),
    ];
    await _persistAll();
  }

  Map<String, int> balancesFor(FairGroup group) =>
      calculateBalances(group, expenses, settlements);

  int get netBalance => groups.fold<int>(
    0,
    (total, group) => total + (balancesFor(group)[currentMemberId] ?? 0),
  );

  int get owedToMe => groups.fold<int>(0, (total, group) {
    final balance = balancesFor(group)[currentMemberId] ?? 0;
    return total + (balance > 0 ? balance : 0);
  });

  int get iOwe => groups.fold<int>(0, (total, group) {
    final balance = balancesFor(group)[currentMemberId] ?? 0;
    return total + (balance < 0 ? -balance : 0);
  });

  List<FairExpense> expensesFor(String groupId) =>
      expenses.where((expense) => expense.groupId == groupId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  Future<FairGroup> addGroup({
    required String groupName,
    required String category,
    String description = '',
    List<String> memberNames = const [],
  }) async {
    final normalizedName = groupName.trim();
    if (normalizedName.isEmpty) throw ArgumentError('Enter a group name.');
    if (groups.any(
      (group) => group.name.toLowerCase() == normalizedName.toLowerCase(),
    )) {
      throw ArgumentError('A group with that name already exists.');
    }
    final members = <FairMember>[currentMember];
    for (final memberName in memberNames.map((name) => name.trim())) {
      if (memberName.isEmpty) continue;
      if (members.any(
        (member) => member.name.toLowerCase() == memberName.toLowerCase(),
      )) {
        continue;
      }
      members.add(FairMember(id: _id(), name: memberName));
    }
    final group = FairGroup(
      id: _id(),
      name: normalizedName,
      category: category,
      description: description.trim(),
      members: members,
      createdAt: DateTime.now(),
    );
    groups = [...groups, group];
    await _persistGroup(group);
    notifyListeners();
    return group;
  }

  Future<void> addMember(String groupId, String memberName) async {
    final group = groups.firstWhere((item) => item.id == groupId);
    final normalizedName = memberName.trim();
    if (normalizedName.isEmpty) throw ArgumentError('Enter a member name.');
    if (group.members.any(
      (member) => member.name.toLowerCase() == normalizedName.toLowerCase(),
    )) {
      throw ArgumentError('That member is already in this group.');
    }
    final updated = FairGroup(
      id: group.id,
      name: group.name,
      category: group.category,
      members: [
        ...group.members,
        FairMember(id: _id(), name: normalizedName),
      ],
      description: group.description,
      icon: group.icon,
      createdAt: group.createdAt,
    );
    groups = groups.map((item) => item.id == groupId ? updated : item).toList();
    await _persistGroup(updated);
    notifyListeners();
  }

  Future<void> saveExpense(FairExpense expense) async {
    final group = groups.firstWhere((item) => item.id == expense.groupId);
    final memberIds = group.members.map((member) => member.id).toSet();
    if (expense.title.trim().isEmpty)
      throw ArgumentError('Enter an expense name.');
    if (expense.amountCents <= 0)
      throw ArgumentError('Amount must be greater than zero.');
    if (!memberIds.contains(expense.paidBy))
      throw ArgumentError('Choose who paid.');
    if (expense.shares.isEmpty ||
        expense.shares.values.any((share) => share < 0)) {
      throw ArgumentError('Choose participants and enter valid shares.');
    }
    if (expense.shares.keys.any((memberId) => !memberIds.contains(memberId))) {
      throw ArgumentError('A split participant is not in this group.');
    }
    if (expense.shares.values.fold<int>(0, (sum, share) => sum + share) !=
        expense.amountCents) {
      throw ArgumentError('Shares must add up to the expense total.');
    }
    expenses = [...expenses.where((item) => item.id != expense.id), expense];
    await _persistExpense(expense);
    notifyListeners();
  }

  Future<void> deleteExpense(String expenseId) async {
    expenses = expenses.where((item) => item.id != expenseId).toList();
    await _database.delete('expenses', where: 'id = ?', whereArgs: [expenseId]);
    notifyListeners();
  }

  Future<void> recordSettlement(FairSettlement settlement) async {
    final group = groups.firstWhere((item) => item.id == settlement.groupId);
    if (settlement.amountCents <= 0)
      throw ArgumentError('Amount must be greater than zero.');
    if (settlement.paidBy == settlement.paidTo) {
      throw ArgumentError('Choose two different members.');
    }
    final balances = balancesFor(group);
    if (!balances.containsKey(settlement.paidBy) ||
        !balances.containsKey(settlement.paidTo)) {
      throw ArgumentError('Choose members from this group.');
    }
    if (balances[settlement.paidBy]! >= 0 ||
        balances[settlement.paidTo]! <= 0) {
      throw ArgumentError('The selected members do not have a debt to settle.');
    }
    if (settlement.amountCents > -balances[settlement.paidBy]! ||
        settlement.amountCents > balances[settlement.paidTo]!) {
      throw ArgumentError('Settlement is larger than the outstanding balance.');
    }
    settlements = [...settlements, settlement];
    await _persistSettlement(settlement);
    notifyListeners();
  }

  Future<void> deleteSettlement(String settlementId) async {
    settlements = settlements.where((item) => item.id != settlementId).toList();
    await _database.delete(
      'settlements',
      where: 'id = ?',
      whereArgs: [settlementId],
    );
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    darkMode = value;
    await _persistPreference('darkMode', '$value');
    notifyListeners();
  }

  Future<void> setCurrency(String value) async {
    currencyCode = value;
    await _persistPreference('currency', value);
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    onboardingComplete = true;
    await _persistPreference('onboardingComplete', 'true');
    notifyListeners();
  }

  Future<void> updateProfile({
    required String name,
    required String email,
  }) async {
    if (name.trim().isEmpty) throw ArgumentError('Enter your name.');
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim())) {
      throw ArgumentError('Enter a valid email address.');
    }
    final previousMemberId = currentMemberId;
    final nextMemberId = _slug(name);
    final previousMember = currentMember;
    this.name = name.trim();
    this.email = email.trim();
    currentMemberId = nextMemberId;
    groups = groups.map((group) {
      if (!group.members.any((member) => member.id == previousMemberId))
        return group;
      return FairGroup(
        id: group.id,
        name: group.name,
        category: group.category,
        members: group.members
            .map(
              (member) => member.id == previousMemberId
                  ? FairMember(
                      id: nextMemberId,
                      name: this.name,
                      email: this.email,
                    )
                  : member,
            )
            .toList(),
        description: group.description,
        icon: group.icon,
        createdAt: group.createdAt,
      );
    }).toList();
    expenses = expenses.map((expense) {
      final shares = Map<String, int>.from(expense.shares);
      if (shares.containsKey(previousMemberId)) {
        shares[nextMemberId] = shares.remove(previousMemberId)!;
      }
      return FairExpense(
        id: expense.id,
        groupId: expense.groupId,
        title: expense.title,
        amountCents: expense.amountCents,
        paidBy: expense.paidBy == previousMemberId
            ? nextMemberId
            : expense.paidBy,
        shares: shares,
        splitMethod: expense.splitMethod,
        category: expense.category,
        date: expense.date,
        notes: expense.notes,
        receiptPath: expense.receiptPath,
      );
    }).toList();
    settlements = settlements
        .map(
          (settlement) => FairSettlement(
            id: settlement.id,
            groupId: settlement.groupId,
            paidBy: settlement.paidBy == previousMemberId
                ? nextMemberId
                : settlement.paidBy,
            paidTo: settlement.paidTo == previousMemberId
                ? nextMemberId
                : settlement.paidTo,
            amountCents: settlement.amountCents,
            date: settlement.date,
            note: settlement.note,
          ),
        )
        .toList();
    if (previousMember.id != currentMemberId) {
      await _database.delete(
        'preferences',
        where: 'key = ?',
        whereArgs: ['memberId'],
      );
    }
    await _persistAll();
    await _persistPreference('memberId', currentMemberId);
    await _persistPreference('name', this.name);
    await _persistPreference('email', this.email);
    notifyListeners();
  }

  Future<void> _persistAll() async {
    await _database.transaction((transaction) async {
      for (final group in groups) {
        await transaction.insert('groups', {
          'id': group.id,
          'payload': jsonEncode(group.toJson()),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final expense in expenses) {
        await transaction.insert('expenses', {
          'id': expense.id,
          'payload': jsonEncode(expense.toJson()),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final settlement in settlements) {
        await transaction.insert('settlements', {
          'id': settlement.id,
          'payload': jsonEncode(settlement.toJson()),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<void> _persistGroup(FairGroup group) => _database.insert('groups', {
    'id': group.id,
    'payload': jsonEncode(group.toJson()),
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> _persistExpense(FairExpense expense) => _database.insert(
    'expenses',
    {'id': expense.id, 'payload': jsonEncode(expense.toJson())},
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  Future<void> _persistSettlement(FairSettlement settlement) =>
      _database.insert('settlements', {
        'id': settlement.id,
        'payload': jsonEncode(settlement.toJson()),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> _persistPreference(String key, String value) => _database.insert(
    'preferences',
    {'key': key, 'value': value},
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  String _id() =>
      '${DateTime.now().microsecondsSinceEpoch}-${groups.length}-${expenses.length}';

  String _slug(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
}
