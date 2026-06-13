/// Modelos de datos para el presupuesto semanal.
/// Estructura basada en el Excel de planificación mensual,
/// adaptada para planificación semanal.

// ─────────────────────────────────────────────
// ITEM DE INGRESO
// ─────────────────────────────────────────────
class IncomeItem {
  String id;
  String name;
  String type; // "Fijo" o "Variable"
  double amount;

  IncomeItem({
    required this.id,
    required this.name,
    required this.type,
    required this.amount,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'amount': amount,
      };

  factory IncomeItem.fromMap(Map<String, dynamic> map) => IncomeItem(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        type: map['type'] ?? 'Fijo',
        amount: (map['amount'] ?? 0).toDouble(),
      );
}

// ─────────────────────────────────────────────
// ITEM DE GASTO
// ─────────────────────────────────────────────
class ExpenseItem {
  String id;
  String name;
  bool isFixed;
  bool isPaidWithCard;
  
  // Gasto Hormiga
  bool isAntExpense;
  
  // Gasto Mensual
  bool isMonthlyExpense;
  DateTime? paymentDate;
  double totalMonthlyAmount;
  
  // Abono Semanal (Monto del presupuesto)
  double amount;

  ExpenseItem({
    required this.id,
    required this.name,
    this.isFixed = false,
    this.isPaidWithCard = false,
    this.isAntExpense = false,
    this.isMonthlyExpense = false,
    this.paymentDate,
    this.totalMonthlyAmount = 0,
    this.amount = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'isFixed': isFixed,
        'isPaidWithCard': isPaidWithCard,
        'isAntExpense': isAntExpense,
        'isMonthlyExpense': isMonthlyExpense,
        'paymentDate': paymentDate?.toIso8601String(),
        'totalMonthlyAmount': totalMonthlyAmount,
        'amount': amount,
      };

  factory ExpenseItem.fromMap(Map<String, dynamic> map) => ExpenseItem(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        isFixed: map['isFixed'] ?? false,
        isPaidWithCard: map['isPaidWithCard'] ?? false,
        isAntExpense: map['isAntExpense'] ?? false,
        isMonthlyExpense: map['isMonthlyExpense'] ?? false,
        paymentDate: map['paymentDate'] != null
            ? DateTime.parse(map['paymentDate'])
            : null,
        totalMonthlyAmount: (map['totalMonthlyAmount'] ?? 0).toDouble(),
        // Fallback a 'monthlyAmount' para compatibilidad con datos viejos
        amount: (map['amount'] ?? map['monthlyAmount'] ?? 0).toDouble(),
      );
}

// ─────────────────────────────────────────────
// CATEGORÍA DE GASTOS
// ─────────────────────────────────────────────
class ExpenseCategory {
  String name;
  String emoji;
  List<ExpenseItem> items;
  bool isAnnual; // Para "Gastos anuales"

  ExpenseCategory({
    required this.name,
    required this.emoji,
    List<ExpenseItem>? items,
    this.isAnnual = false,
  }) : items = items ?? [];

  double get total =>
      items.fold(0, (sum, item) => sum + item.amount);

  double get fixedTotal =>
      items.where((i) => i.isFixed).fold(0, (sum, item) => sum + item.amount);

  double get variableTotal =>
      items.where((i) => !i.isFixed).fold(0, (sum, item) => sum + item.amount);

  double get antExpenseTotal => items.where((i) => i.isAntExpense).fold(
      0, (sum, item) => sum + item.amount);

  Map<String, dynamic> toMap() => {
        'name': name,
        'emoji': emoji,
        'isAnnual': isAnnual,
        'items': items.map((i) => i.toMap()).toList(),
      };

  factory ExpenseCategory.fromMap(Map<String, dynamic> map) => ExpenseCategory(
        name: map['name'] ?? '',
        emoji: map['emoji'] ?? '📦',
        isAnnual: map['isAnnual'] ?? false,
        items: (map['items'] as List<dynamic>?)
                ?.map((i) => ExpenseItem.fromMap(i as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

// ─────────────────────────────────────────────
// DATOS DEL PRESUPUESTO SEMANAL
// ─────────────────────────────────────────────
class BudgetData {
  String weekId; // Formato: "2026-W24" (año-semana ISO)
  List<IncomeItem> incomes;
  double savingsPercentage;
  List<ExpenseCategory> expenseCategories;
  DateTime createdAt;
  DateTime updatedAt;

  BudgetData({
    required this.weekId,
    List<IncomeItem>? incomes,
    this.savingsPercentage = 10,
    List<ExpenseCategory>? expenseCategories,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : incomes = incomes ?? [],
        expenseCategories = expenseCategories ?? _defaultCategories(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // ── Cálculos automáticos ──

  double get totalIncome =>
      incomes.fold(0, (sum, item) => sum + item.amount);

  double get fixedIncome =>
      incomes.where((i) => i.type == 'Fijo').fold(0, (sum, item) => sum + item.amount);

  double get variableIncome =>
      incomes.where((i) => i.type == 'Variable').fold(0, (sum, item) => sum + item.amount);

  double get annualEstimatedIncome => totalIncome * 52; // 52 semanas

  double get monthlySavingsGoal => totalIncome * savingsPercentage / 100;

  double get totalExpenses =>
      expenseCategories.fold(0, (sum, cat) => sum + cat.total);

  double get totalFixedExpenses =>
      expenseCategories.fold(0, (sum, cat) => sum + cat.fixedTotal);

  double get totalVariableExpenses =>
      expenseCategories.fold(0, (sum, cat) => sum + cat.variableTotal);

  double get availableAtEndOfWeek => totalIncome - totalExpenses;

  double get antExpenseBudget =>
      expenseCategories.fold(0, (sum, cat) => sum + cat.antExpenseTotal);

  double get maxDailyAntExpense =>
      antExpenseBudget > 0 ? antExpenseBudget / 7 : 0; // 7 días por semana

  // ── Serialización ──

  Map<String, dynamic> toMap() => {
        'weekId': weekId,
        'incomes': incomes.map((i) => i.toMap()).toList(),
        'savingsPercentage': savingsPercentage,
        'expenseCategories': expenseCategories.map((c) => c.toMap()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

  factory BudgetData.fromMap(Map<String, dynamic> map) => BudgetData(
        weekId: map['weekId'] ?? '',
        incomes: (map['incomes'] as List<dynamic>?)
                ?.map((i) => IncomeItem.fromMap(i as Map<String, dynamic>))
                .toList() ??
            [],
        savingsPercentage: (map['savingsPercentage'] ?? 10).toDouble(),
        expenseCategories: (map['expenseCategories'] as List<dynamic>?)
                ?.map((c) =>
                    ExpenseCategory.fromMap(c as Map<String, dynamic>))
                .toList() ??
            _defaultCategories(),
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'])
            : DateTime.now(),
        updatedAt: map['updatedAt'] != null
            ? DateTime.parse(map['updatedAt'])
            : DateTime.now(),
      );

  /// Categorías por defecto (vacías) basadas en el Excel
  static List<ExpenseCategory> _defaultCategories() => [
        ExpenseCategory(name: 'Casa', emoji: '🏠'),
        ExpenseCategory(name: 'Comida', emoji: '🍔'),
        ExpenseCategory(name: 'Familia', emoji: '❤️'),
        ExpenseCategory(name: 'Transporte', emoji: '🚗'),
        ExpenseCategory(name: 'Viajes', emoji: '✈️'),
        ExpenseCategory(name: 'Deudas', emoji: '💳'),
        ExpenseCategory(name: 'Salud', emoji: '🏥'),
        ExpenseCategory(name: 'Suscripciones', emoji: '📱'),
        ExpenseCategory(name: 'Gastos anuales', emoji: '📅', isAnnual: true),
        ExpenseCategory(name: 'Cuidado personal', emoji: '💅'),
        ExpenseCategory(name: 'Entretenimiento', emoji: '🎭'),
        ExpenseCategory(name: 'Otros', emoji: '📦'),
      ];
}
