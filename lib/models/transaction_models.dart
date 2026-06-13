/// Modelos de datos para el tracker de gastos reales.

// ─────────────────────────────────────────────
// ITEM DE TRANSACCIÓN (GASTO REAL)
// ─────────────────────────────────────────────
class TransactionItem {
  String id;
  String description;
  double amount;
  String categoryName;
  String categoryEmoji;
  String paidBy; // "Miri", "Luisito", "Ambos"
  String? note;
  DateTime date;
  bool isAntExpense;

  TransactionItem({
    required this.id,
    required this.description,
    required this.amount,
    required this.categoryName,
    required this.categoryEmoji,
    required this.paidBy,
    this.note,
    required this.date,
    this.isAntExpense = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'description': description,
        'amount': amount,
        'categoryName': categoryName,
        'categoryEmoji': categoryEmoji,
        'paidBy': paidBy,
        'note': note,
        'date': date.toIso8601String(),
        'isAntExpense': isAntExpense,
      };

  factory TransactionItem.fromMap(Map<String, dynamic> map) => TransactionItem(
        id: map['id'] ?? '',
        description: map['description'] ?? '',
        amount: (map['amount'] ?? 0).toDouble(),
        categoryName: map['categoryName'] ?? '',
        categoryEmoji: map['categoryEmoji'] ?? '📦',
        paidBy: map['paidBy'] ?? 'Ambos',
        note: map['note'],
        date: map['date'] != null
            ? DateTime.parse(map['date'])
            : DateTime.now(),
        isAntExpense: map['isAntExpense'] ?? false,
      );
}

// ─────────────────────────────────────────────
// TRANSACCIONES DE UNA SEMANA
// ─────────────────────────────────────────────
class WeeklyTransactions {
  String weekId;
  List<TransactionItem> transactions;

  WeeklyTransactions({
    required this.weekId,
    List<TransactionItem>? transactions,
  }) : transactions = transactions ?? [];

  double get totalSpent =>
      transactions.fold(0, (sum, t) => sum + t.amount);

  double totalByCategory(String categoryName) => transactions
      .where((t) => t.categoryName == categoryName)
      .fold(0, (sum, t) => sum + t.amount);

  double get antExpenseTotal => transactions
      .where((t) => t.isAntExpense)
      .fold(0, (sum, t) => sum + t.amount);

  /// Transacciones de hoy
  List<TransactionItem> get todayTransactions {
    final now = DateTime.now();
    return transactions
        .where((t) =>
            t.date.year == now.year &&
            t.date.month == now.month &&
            t.date.day == now.day)
        .toList();
  }

  /// Agrupa transacciones por día (fecha sin hora)
  Map<DateTime, List<TransactionItem>> get groupedByDay {
    final map = <DateTime, List<TransactionItem>>{};
    for (final t in transactions) {
      final key = DateTime(t.date.year, t.date.month, t.date.day);
      map.putIfAbsent(key, () => []).add(t);
    }
    // Ordenar por día más reciente primero
    final sorted = Map.fromEntries(
      map.entries.toList()..sort((a, b) => b.key.compareTo(a.key)),
    );
    return sorted;
  }

  // ── Serialización ──

  Map<String, dynamic> toMap() => {
        'weekId': weekId,
        'transactions': transactions.map((t) => t.toMap()).toList(),
      };

  factory WeeklyTransactions.fromMap(Map<String, dynamic> map) =>
      WeeklyTransactions(
        weekId: map['weekId'] ?? '',
        transactions: (map['transactions'] as List<dynamic>?)
                ?.map(
                    (t) => TransactionItem.fromMap(t as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
