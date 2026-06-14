import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../main.dart'; // Para AppColors
import '../../models/goal_models.dart';
import 'providers/goal_provider.dart';
import 'widgets/add_goal_sheet.dart';
import 'widgets/add_debt_sheet.dart';
import 'widgets/add_payment_sheet.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsDataProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: goalsAsync.when(
          data: (data) => _buildContent(context, data, ref),
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.lavender),
          ),
          error: (err, stack) => Center(
            child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, FinancialGoalsData data, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Metas y Ahorro 🎯',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Juntos lo logramos 💪',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _showAddGoalSheet(context),
                    icon: const Icon(Icons.add_task, color: AppColors.lavender),
                    tooltip: 'Nueva Meta',
                  ),
                  IconButton(
                    onPressed: () => _showAddDebtSheet(context),
                    icon: const Icon(Icons.credit_card, color: AppColors.pink),
                    tooltip: 'Nueva Deuda',
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 24),

          // Resumen total ahorrado y gráfico
          _buildGlobalProgress(data),
          
          const SizedBox(height: 32),

          // Tarjetas de metas individuales
          const Text(
            'Tus Metas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (data.savingsGoals.isEmpty)
            const Text('No hay metas. ¡Añade la primera!', style: TextStyle(color: AppColors.textSecondary))
          else
            ...data.savingsGoals.map((goal) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildGoalDetailCard(context, goal, ref),
            )),
            
          const SizedBox(height: 24),

          // Deudas activas
          const Text(
            'Deudas activas 💳',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (data.debts.isEmpty)
            const Text('¡Excelente! No hay deudas activas.', style: TextStyle(color: AppColors.mint))
          else
            ...data.debts.map((debt) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildDebtCard(context, debt, ref),
            )),
        ],
      ),
    );
  }

  Widget _buildGlobalProgress(FinancialGoalsData data) {
    final double totalTarget = data.totalTarget > 0 ? data.totalTarget : 1;
    final double totalSaved = data.totalSaved;
    final double percentage = (totalSaved / totalTarget).clamp(0.0, 1.0);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.lavender.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Progreso Global',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 60,
                    startDegreeOffset: -90,
                    sections: [
                      PieChartSectionData(
                        color: AppColors.mint,
                        value: percentage,
                        title: '',
                        radius: 20,
                      ),
                      PieChartSectionData(
                        color: AppColors.mintLight.withOpacity(0.5),
                        value: 1 - percentage,
                        title: '',
                        radius: 20,
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(percentage * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.mint,
                      ),
                    ),
                    const Text(
                      'Ahorrado',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  const Text('Total', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Text('\$${totalSaved.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.mint, fontSize: 16)),
                ],
              ),
              Container(width: 1, height: 30, color: AppColors.textLight.withOpacity(0.3)),
              Column(
                children: [
                  const Text('Objetivo', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Text('\$${data.totalTarget.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 16)),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildGoalDetailCard(BuildContext context, SavingsGoal goal, WidgetRef ref) {
    double progress = goal.targetAmount > 0 ? (goal.currentAmount / goal.targetAmount) : 0;
    progress = progress.clamp(0.0, 1.0);
    final color = Color(int.parse(goal.colorHex.replaceFirst('#', '0xFF')));
    final bgColor = color.withOpacity(0.2);

    int? daysLeft;
    if (goal.deadline != null) {
      daysLeft = goal.deadline!.difference(DateTime.now()).inDays;
      if (daysLeft < 0) daysLeft = 0;
    }

    return GestureDetector(
      onLongPress: () => _showAddGoalSheet(context, goalToEdit: goal),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                      child: Text(goal.emoji, style: const TextStyle(fontSize: 26))),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(goal.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: AppColors.textPrimary)),
                      if (daysLeft != null)
                        Text('Faltan $daysLeft días',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showAddPaymentSheet(context, goal: goal),
                  icon: Icon(Icons.add_circle, color: color, size: 28),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: color.withOpacity(0.12),
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${goal.currentAmount.toStringAsFixed(0)} ahorrado',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
                Text(
                  'Meta: \$${goal.targetAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
            if (goal.monthlyTarget > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 14, color: color),
                    const SizedBox(width: 6),
                    Text(
                      'Aporte mensual: \$${goal.monthlyTarget.toStringAsFixed(0)}',
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildDebtCard(BuildContext context, DebtItem debt, WidgetRef ref) {
    final color = Color(int.parse(debt.colorHex.replaceFirst('#', '0xFF')));

    return GestureDetector(
      onLongPress: () => _showAddDebtSheet(context, debtToEdit: debt),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.coral.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: AppColors.coral.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.credit_card_rounded, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(debt.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppColors.textPrimary)),
                  Text('Pago mensual: \$${debt.monthlyPayment.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('-\$${debt.balance.toStringAsFixed(0)}',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: color)),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _showAddPaymentSheet(context, debt: debt),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.coral.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Abonar',
                      style: TextStyle(color: AppColors.coral, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddGoalSheet(BuildContext context, {SavingsGoal? goalToEdit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddGoalSheet(goalToEdit: goalToEdit),
    );
  }

  void _showAddDebtSheet(BuildContext context, {DebtItem? debtToEdit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddDebtSheet(debtToEdit: debtToEdit),
    );
  }

  void _showAddPaymentSheet(BuildContext context, {SavingsGoal? goal, DebtItem? debt}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddPaymentSheet(goal: goal, debt: debt),
    );
  }
}
