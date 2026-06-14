import 'package:flutter/material.dart';

/// Modelo de datos para una Meta de Ahorro
class SavingsGoal {
  String id;
  String title;
  String emoji;
  double currentAmount;
  double targetAmount;
  double monthlyTarget;
  DateTime? deadline;
  String colorHex;

  SavingsGoal({
    required this.id,
    required this.title,
    required this.emoji,
    required this.currentAmount,
    required this.targetAmount,
    required this.monthlyTarget,
    this.deadline,
    required this.colorHex,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'emoji': emoji,
        'currentAmount': currentAmount,
        'targetAmount': targetAmount,
        'monthlyTarget': monthlyTarget,
        'deadline': deadline?.toIso8601String(),
        'colorHex': colorHex,
      };

  factory SavingsGoal.fromMap(Map<String, dynamic> map) => SavingsGoal(
        id: map['id'] ?? '',
        title: map['title'] ?? '',
        emoji: map['emoji'] ?? '🎯',
        currentAmount: (map['currentAmount'] ?? 0).toDouble(),
        targetAmount: (map['targetAmount'] ?? 0).toDouble(),
        monthlyTarget: (map['monthlyTarget'] ?? 0).toDouble(),
        deadline: map['deadline'] != null ? DateTime.parse(map['deadline']) : null,
        colorHex: map['colorHex'] ?? '#B8A9E8', // Default lavender
      );

  SavingsGoal copyWith({
    String? id,
    String? title,
    String? emoji,
    double? currentAmount,
    double? targetAmount,
    double? monthlyTarget,
    DateTime? deadline,
    String? colorHex,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      emoji: emoji ?? this.emoji,
      currentAmount: currentAmount ?? this.currentAmount,
      targetAmount: targetAmount ?? this.targetAmount,
      monthlyTarget: monthlyTarget ?? this.monthlyTarget,
      deadline: deadline ?? this.deadline,
      colorHex: colorHex ?? this.colorHex,
    );
  }
}

/// Modelo de datos para una Deuda Activa
class DebtItem {
  String id;
  String title;
  double balance;
  double monthlyPayment;
  String colorHex;

  DebtItem({
    required this.id,
    required this.title,
    required this.balance,
    required this.monthlyPayment,
    required this.colorHex,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'balance': balance,
        'monthlyPayment': monthlyPayment,
        'colorHex': colorHex,
      };

  factory DebtItem.fromMap(Map<String, dynamic> map) => DebtItem(
        id: map['id'] ?? '',
        title: map['title'] ?? '',
        balance: (map['balance'] ?? 0).toDouble(),
        monthlyPayment: (map['monthlyPayment'] ?? 0).toDouble(),
        colorHex: map['colorHex'] ?? '#F2B5D4', // Default pink
      );

  DebtItem copyWith({
    String? id,
    String? title,
    double? balance,
    double? monthlyPayment,
    String? colorHex,
  }) {
    return DebtItem(
      id: id ?? this.id,
      title: title ?? this.title,
      balance: balance ?? this.balance,
      monthlyPayment: monthlyPayment ?? this.monthlyPayment,
      colorHex: colorHex ?? this.colorHex,
    );
  }
}

/// Modelo agrupador para guardar en Firestore
class FinancialGoalsData {
  List<SavingsGoal> savingsGoals;
  List<DebtItem> debts;

  FinancialGoalsData({
    List<SavingsGoal>? savingsGoals,
    List<DebtItem>? debts,
  })  : savingsGoals = savingsGoals ?? [],
        debts = debts ?? [];

  double get totalSaved => savingsGoals.fold(0, (sum, goal) => sum + goal.currentAmount);
  double get totalTarget => savingsGoals.fold(0, (sum, goal) => sum + goal.targetAmount);
  double get totalDebt => debts.fold(0, (sum, debt) => sum + debt.balance);

  Map<String, dynamic> toMap() => {
        'savingsGoals': savingsGoals.map((g) => g.toMap()).toList(),
        'debts': debts.map((d) => d.toMap()).toList(),
      };

  factory FinancialGoalsData.fromMap(Map<String, dynamic> map) => FinancialGoalsData(
        savingsGoals: (map['savingsGoals'] as List<dynamic>?)
                ?.map((g) => SavingsGoal.fromMap(g as Map<String, dynamic>))
                .toList() ??
            [],
        debts: (map['debts'] as List<dynamic>?)
                ?.map((d) => DebtItem.fromMap(d as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
