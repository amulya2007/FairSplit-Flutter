enum SplitMethod { equal, custom, percentage }

class FairMember {
  const FairMember({required this.id, required this.name, this.email = ''});

  final String id;
  final String name;
  final String email;

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'email': email};

  factory FairMember.fromJson(Map<String, dynamic> json) => FairMember(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String? ?? '',
  );
}

class FairGroup {
  const FairGroup({
    required this.id,
    required this.name,
    required this.category,
    required this.members,
    this.description = '',
    this.icon = 'groups',
    this.createdAt,
  });

  final String id;
  final String name;
  final String category;
  final List<FairMember> members;
  final String description;
  final String icon;
  final DateTime? createdAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'members': members.map((member) => member.toJson()).toList(),
    'description': description,
    'icon': icon,
    'createdAt': createdAt?.toIso8601String(),
  };

  factory FairGroup.fromJson(Map<String, dynamic> json) => FairGroup(
    id: json['id'] as String,
    name: json['name'] as String,
    category: json['category'] as String? ?? 'Other',
    members: (json['members'] as List<dynamic>? ?? [])
        .map((member) => FairMember.fromJson(member as Map<String, dynamic>))
        .toList(),
    description: json['description'] as String? ?? '',
    icon: json['icon'] as String? ?? 'groups',
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
  );
}

class FairExpense {
  const FairExpense({
    required this.id,
    required this.groupId,
    required this.title,
    required this.amountCents,
    required this.paidBy,
    required this.shares,
    required this.splitMethod,
    required this.category,
    required this.date,
    this.notes = '',
    this.receiptPath,
  });

  final String id;
  final String groupId;
  final String title;
  final int amountCents;
  final String paidBy;
  final Map<String, int> shares;
  final SplitMethod splitMethod;
  final String category;
  final DateTime date;
  final String notes;
  final String? receiptPath;

  Map<String, Object?> toJson() => {
    'id': id,
    'groupId': groupId,
    'title': title,
    'amountCents': amountCents,
    'paidBy': paidBy,
    'shares': shares,
    'splitMethod': splitMethod.name,
    'category': category,
    'date': date.toIso8601String(),
    'notes': notes,
    'receiptPath': receiptPath,
  };

  factory FairExpense.fromJson(Map<String, dynamic> json) => FairExpense(
    id: json['id'] as String,
    groupId: json['groupId'] as String,
    title: json['title'] as String,
    amountCents: json['amountCents'] as int,
    paidBy: json['paidBy'] as String,
    shares: (json['shares'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, value as int),
    ),
    splitMethod: SplitMethod.values.firstWhere(
      (method) => method.name == json['splitMethod'],
      orElse: () => SplitMethod.equal,
    ),
    category: json['category'] as String? ?? 'Other',
    date: DateTime.parse(json['date'] as String),
    notes: json['notes'] as String? ?? '',
    receiptPath: json['receiptPath'] as String?,
  );
}

class FairSettlement {
  const FairSettlement({
    required this.id,
    required this.groupId,
    required this.paidBy,
    required this.paidTo,
    required this.amountCents,
    required this.date,
    this.note = '',
  });

  final String id;
  final String groupId;
  final String paidBy;
  final String paidTo;
  final int amountCents;
  final DateTime date;
  final String note;

  Map<String, Object?> toJson() => {
    'id': id,
    'groupId': groupId,
    'paidBy': paidBy,
    'paidTo': paidTo,
    'amountCents': amountCents,
    'date': date.toIso8601String(),
    'note': note,
  };

  factory FairSettlement.fromJson(Map<String, dynamic> json) =>
      FairSettlement(
        id: json['id'] as String,
        groupId: json['groupId'] as String,
        paidBy: json['paidBy'] as String,
        paidTo: json['paidTo'] as String,
        amountCents: json['amountCents'] as int,
        date: DateTime.parse(json['date'] as String),
        note: json['note'] as String? ?? '',
      );
}

class SuggestedPayment {
  const SuggestedPayment({
    required this.payer,
    required this.payee,
    required this.amountCents,
  });

  final FairMember payer;
  final FairMember payee;
  final int amountCents;
}

Map<String, int> calculateBalances(
  FairGroup group,
  Iterable<FairExpense> expenses,
  Iterable<FairSettlement> settlements,
) {
  final balances = {for (final member in group.members) member.id: 0};

  for (final expense in expenses.where((item) => item.groupId == group.id)) {
    if (!balances.containsKey(expense.paidBy)) continue;
    balances[expense.paidBy] = balances[expense.paidBy]! + expense.amountCents;
    for (final entry in expense.shares.entries) {
      if (balances.containsKey(entry.key)) {
        balances[entry.key] = balances[entry.key]! - entry.value;
      }
    }
  }

  for (final settlement in settlements.where(
    (item) => item.groupId == group.id,
  )) {
    if (balances.containsKey(settlement.paidBy)) {
      balances[settlement.paidBy] =
          balances[settlement.paidBy]! + settlement.amountCents;
    }
    if (balances.containsKey(settlement.paidTo)) {
      balances[settlement.paidTo] =
          balances[settlement.paidTo]! - settlement.amountCents;
    }
  }

  return balances;
}

List<SuggestedPayment> simplifyDebts(
  FairGroup group,
  Map<String, int> balances,
) {
  final members = {for (final member in group.members) member.id: member};
  final debtors = balances.entries
      .where((entry) => entry.value < 0 && members.containsKey(entry.key))
      .map((entry) => MapEntry(entry.key, -entry.value))
      .toList();
  final creditors = balances.entries
      .where((entry) => entry.value > 0 && members.containsKey(entry.key))
      .toList();
  final payments = <SuggestedPayment>[];
  var debtorIndex = 0;
  var creditorIndex = 0;

  while (debtorIndex < debtors.length && creditorIndex < creditors.length) {
    final debtor = debtors[debtorIndex];
    final creditor = creditors[creditorIndex];
    final amount = debtor.value < creditor.value
        ? debtor.value
        : creditor.value;
    if (amount > 0) {
      payments.add(
        SuggestedPayment(
          payer: members[debtor.key]!,
          payee: members[creditor.key]!,
          amountCents: amount,
        ),
      );
    }
    debtors[debtorIndex] = MapEntry(debtor.key, debtor.value - amount);
    creditors[creditorIndex] = MapEntry(creditor.key, creditor.value - amount);
    if (debtors[debtorIndex].value == 0) debtorIndex++;
    if (creditors[creditorIndex].value == 0) creditorIndex++;
  }

  return payments;
}