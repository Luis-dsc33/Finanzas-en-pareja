import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../models/budget_models.dart';
import '../../services/firebase/budget_service.dart';
import '../../main.dart'; // Para AppColors

// ─────────────────────────────────────────────
// PANTALLA PRESUPUESTO SEMANAL
// ─────────────────────────────────────────────
class BudgetScreen extends StatefulWidget {
  const BudgetScreen({Key? key}) : super(key: key);

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen>
    with TickerProviderStateMixin {
  final BudgetService _budgetService = BudgetService();
  late String _currentWeekId;
  BudgetData? _budget;
  bool _isLoading = true;
  final Set<int> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    _currentWeekId = BudgetService.getCurrentWeekId();
    _loadBudget();
  }

  Future<void> _loadBudget() async {
    setState(() => _isLoading = true);
    BudgetData? budget = await _budgetService.getBudget(_currentWeekId);
    
    if (budget == null) {
      // Auto-copy previous week
      final prevWeekId = BudgetService.getPreviousWeekId(_currentWeekId);
      budget = await _budgetService.duplicateFromWeek(prevWeekId, _currentWeekId);
      
      // If previous week doesn't exist either, create empty
      if (budget == null) {
        budget = BudgetData(weekId: _currentWeekId);
      }
    }
    
    setState(() {
      _budget = budget;
      _isLoading = false;
    });
  }

  Future<void> _saveBudget() async {
    if (_budget != null) {
      await _budgetService.saveBudget(_budget!);
    }
  }

  void _navigateWeek(int direction) {
    setState(() {
      _currentWeekId = direction > 0
          ? BudgetService.getNextWeekId(_currentWeekId)
          : BudgetService.getPreviousWeekId(_currentWeekId);
    });
    _loadBudget();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.lavender),
            )
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        const Text(
                          'Presupuesto semanal 📊',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Planifica y controla tus finanzas',
                          style: TextStyle(
                              fontSize: 14, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),

                        // Navegación de semanas
                        _buildWeekNavigator(),
                        const SizedBox(height: 20),

                        // Sección 1: Ingresos
                        _buildIncomesSection(),
                        const SizedBox(height: 16),

                        // Sección 2: Meta de Ahorro
                        _buildSavingsGoalSection(),
                        const SizedBox(height: 16),

                        // Sección 3: Resumen
                        _buildSummarySection(),
                        const SizedBox(height: 16),

                        // Sección 4: Gastos Hormiga
                        _buildAntExpensesSection(),
                        const SizedBox(height: 20),

                        // Título Detalle de Gastos
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.lavenderLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text('📋',
                                  style: TextStyle(fontSize: 18)),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Detalle de gastos',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),

                // Sección 5: Categorías de Gastos (expandibles)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (_budget == null) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildExpenseCategoryCard(index),
                        );
                      },
                      childCount:
                          _budget?.expenseCategories.length ?? 0,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ── NAVEGADOR DE SEMANAS ──
  Widget _buildWeekNavigator() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _navigateWeek(-1),
            icon: const Icon(Icons.chevron_left_rounded),
            color: AppColors.lavender,
            iconSize: 28,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  _currentWeekId,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  BudgetService.formatWeekRange(_currentWeekId),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _navigateWeek(1),
            icon: const Icon(Icons.chevron_right_rounded),
            color: AppColors.lavender,
            iconSize: 28,
          ),
        ],
      ),
    );
  }

  // ── SECCIÓN INGRESOS ──
  Widget _buildIncomesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.mintLight,
            AppColors.mint.withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.mint.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.mint.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('💰', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Ingresos Promedio Semanales',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _showAddIncomeDialog(),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.mint.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: AppColors.textPrimary, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Lista de ingresos
          if (_budget!.incomes.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    const Text('📭', style: TextStyle(fontSize: 32)),
                    const SizedBox(height: 8),
                    Text(
                      'Sin ingresos registrados',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Toca + para agregar uno',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...List.generate(_budget!.incomes.length, (index) {
              final income = _budget!.incomes[index];
              return Dismissible(
                key: Key(income.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.coral.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_rounded,
                      color: AppColors.coral, size: 22),
                ),
                onDismissed: (_) {
                  setState(() => _budget!.incomes.removeAt(index));
                  _saveBudget();
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              income.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: income.type == 'Fijo'
                                    ? AppColors.lavender.withOpacity(0.15)
                                    : AppColors.peach.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                income.type,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: income.type == 'Fijo'
                                      ? AppColors.lavenderDark
                                      : const Color(0xFFD4854A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '\$${income.amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Color(0xFF2E7D4F),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() => _budget!.incomes.removeAt(index));
                          _saveBudget();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.coral.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.delete_outline_rounded,
                              color: AppColors.coral, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

          const Divider(color: AppColors.mint, height: 24),

          // Totales
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total de Ingresos',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '\$${_budget!.totalIncome.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: Color(0xFF2E7D4F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ingresos anuales estimados',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '\$${_budget!.annualEstimatedIncome.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── SECCIÓN META DE AHORRO ──
  Widget _buildSavingsGoalSection() {
    final percentage = _budget!.savingsPercentage;
    final savingsGoal = _budget!.monthlySavingsGoal;
    String motivationalMessage;
    String emoji;

    if (percentage >= 20) {
      motivationalMessage = '¡Increíble! Eres un campeón del ahorro 💪';
      emoji = '🏆';
    } else if (percentage >= 10) {
      motivationalMessage =
          'Este es un buen porcentaje. ¡Ten disciplina para lograrlo!';
      emoji = '✨';
    } else if (percentage > 0) {
      motivationalMessage = 'Cada peso cuenta. ¡Intenta subir un poco más!';
      emoji = '💪';
    } else {
      motivationalMessage = 'Establece una meta de ahorro para empezar';
      emoji = '🎯';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.lavender.withOpacity(0.2)),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.lavenderLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('🎯', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 10),
              const Text(
                '¿Cuánto quieres ahorrar?',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Slider de porcentaje
          Row(
            children: [
              Text(
                '${percentage.toInt()}%',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.lavenderDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'de tus ingresos',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Meta semanal: \$${savingsGoal.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.lavenderDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.lavender,
              inactiveTrackColor: AppColors.lavenderLight,
              thumbColor: AppColors.lavenderDark,
              overlayColor: AppColors.lavender.withOpacity(0.2),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: percentage,
              min: 0,
              max: 50,
              divisions: 50,
              onChanged: (value) {
                setState(() => _budget!.savingsPercentage = value);
              },
              onChangeEnd: (_) => _saveBudget(),
            ),
          ),

          // Mensaje motivacional
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.lavenderLight.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    motivationalMessage,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── SECCIÓN RESUMEN ──
  Widget _buildSummarySection() {
    final available = _budget!.availableAtEndOfWeek;
    final isPositive = available >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFCBB6F0),
            const Color(0xFFE8A4C8),
            const Color(0xFFF2C6A0),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.lavender.withOpacity(0.25),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen de Ingresos y Gastos',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Ingresos
          _buildSummaryRow(
              'Ingresos Fijos', _budget!.fixedIncome, Colors.white),
          const SizedBox(height: 6),
          _buildSummaryRow(
              'Ingresos Variables', _budget!.variableIncome, Colors.white),
          _buildSummaryDivider(),
          _buildSummaryRow(
              'Total de Ingresos', _budget!.totalIncome, Colors.white,
              isBold: true),

          const SizedBox(height: 16),

          // Gastos
          _buildSummaryRow(
              'Gastos Fijos', _budget!.totalFixedExpenses, Colors.white70),
          const SizedBox(height: 6),
          _buildSummaryRow('Gastos Variables', _budget!.totalVariableExpenses,
              Colors.white70),
          _buildSummaryDivider(),
          _buildSummaryRow(
              'Total de Gastos', _budget!.totalExpenses, Colors.white70,
              isBold: true),

          const SizedBox(height: 20),

          // Disponible
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Disponible al final',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const Text(
                      'de la semana',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${isPositive ? '' : '-'}\$${available.abs().toStringAsFixed(0)}',
                  style: TextStyle(
                    color: isPositive ? Colors.white : const Color(0xFFFFCDD2),
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, Color color,
      {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(0)}',
          style: TextStyle(
            color: color,
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Divider(color: Colors.white.withOpacity(0.3), height: 1),
    );
  }

  // ── SECCIÓN GASTOS HORMIGA ──
  Widget _buildAntExpensesSection() {
    final antBudget = _budget!.antExpenseBudget;
    final maxDaily = _budget!.maxDailyAntExpense;

    String message;
    Color alertColor;
    String alertEmoji;

    if (antBudget == 0) {
      message = 'Agrega gastos con porcentaje hormiga para ver el cálculo';
      alertColor = AppColors.textSecondary;
      alertEmoji = '💤';
    } else if (maxDaily > 100) {
      message =
          '¡Bien! Puedes lograr tus metas de ahorro y darte un gustito 🍦';
      alertColor = AppColors.mint;
      alertEmoji = '😊';
    } else if (maxDaily > 50) {
      message =
          'Para lograr tu meta de ahorro, recorta esto de tus gastos hormiga';
      alertColor = AppColors.peach;
      alertEmoji = '⚠️';
    } else {
      message = '¡Cuidado! Tus gastos hormiga están muy altos';
      alertColor = AppColors.coral;
      alertEmoji = '🚨';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.lemonLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.lemon.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.lemon.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('🐜', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  '¡Cuidado con los gastos hormiga!',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildAntStatCard(
                  'Presupuesto semanal\npara gastos hormiga',
                  '\$${antBudget.toStringAsFixed(0)}',
                  AppColors.lemon,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildAntStatCard(
                  'Puedes gastar\nmáximo al día',
                  '\$${maxDaily.toStringAsFixed(0)}',
                  AppColors.peach,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: alertColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: alertColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Text(alertEmoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAntStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ── TARJETA DE CATEGORÍA DE GASTOS ──

  // Colores por categoría
  static const List<List<Color>> _categoryColors = [
    [Color(0xFFE3F2FD), Color(0xFF90CAF9)], // Casa
    [Color(0xFFE8F5E9), Color(0xFFA5D6A7)], // Comida
    [Color(0xFFFCE4EC), Color(0xFFF48FB1)], // Familia
    [Color(0xFFE3F2FD), Color(0xFF81D4FA)], // Transporte
    [Color(0xFFFFF8E1), Color(0xFFFFD54F)], // Viajes
    [Color(0xFFE8F5E9), Color(0xFF81C784)], // Deudas
    [Color(0xFFE0F7FA), Color(0xFF80DEEA)], // Salud
    [Color(0xFFE8F5E9), Color(0xFFA5D6A7)], // Suscripciones
    [Color(0xFFF1F8E9), Color(0xFFAED581)], // Gastos anuales
    [Color(0xFFE3F2FD), Color(0xFF90CAF9)], // Cuidado personal
    [Color(0xFFE8F5E9), Color(0xFFA5D6A7)], // Entretenimiento
    [Color(0xFFF3E5F5), Color(0xFFCE93D8)], // Otros
  ];

  Widget _buildExpenseCategoryCard(int index) {
    final category = _budget!.expenseCategories[index];
    final isExpanded = _expandedCategories.contains(index);
    final colors = _categoryColors[index % _categoryColors.length];
    final amountLabel = category.isAnnual ? 'Monto anual' : 'Monto semanal';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isExpanded ? colors[0] : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isExpanded ? colors[1].withOpacity(0.5) : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isExpanded
                ? colors[1].withOpacity(0.15)
                : Colors.black.withOpacity(0.03),
            blurRadius: isExpanded ? 12 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header de la categoría
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedCategories.remove(index);
                } else {
                  _expandedCategories.add(index);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: colors[1].withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(category.emoji,
                          style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${category.items.length} gastos',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '\$${category.total.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: colors[1].withOpacity(1),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Contenido expandido
          if (isExpanded) ...[
            Divider(
              color: colors[1].withOpacity(0.3),
              height: 1,
              indent: 16,
              endIndent: 16,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                children: [
                  // Header de columnas
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    child: Row(
                      children: [
                        const Expanded(
                          flex: 3,
                          child: Text('Gasto',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary)),
                        ),
                        SizedBox(
                          width: 32,
                          child: Center(
                            child: Text('Fijo',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary)),
                          ),
                        ),
                        SizedBox(
                          width: 32,
                          child: Center(
                            child: Text('💳',
                                style: TextStyle(fontSize: 14)),
                          ),
                        ),
                        SizedBox(
                          width: 32,
                          child: Center(
                            child: Text('🐜',
                                style: TextStyle(fontSize: 14)),
                          ),
                        ),
                        SizedBox(
                          width: 64,
                          child: Center(
                            child: Text(amountLabel,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary)),
                          ),
                        ),
                        const SizedBox(width: 28),
                      ],
                    ),
                  ),

                  // Items
                  ...List.generate(category.items.length, (itemIndex) {
                    return _buildExpenseItemRow(
                        index, itemIndex, category.items[itemIndex], colors);
                  }),

                  // Botón agregar
                  GestureDetector(
                    onTap: () =>
                        _showAddExpenseDialog(index),
                    child: Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: colors[1].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: colors[1].withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_rounded,
                              size: 18, color: colors[1]),
                          const SizedBox(width: 6),
                          Text(
                            'Agregar gasto',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colors[1],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Total
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors[1].withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '\$${category.total.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: colors[1],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildExpenseItemRow(
      int catIndex, int itemIndex, ExpenseItem item, List<Color> colors) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 12),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: AppColors.coral.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.delete_rounded,
            color: AppColors.coral, size: 20),
      ),
      onDismissed: (_) {
        setState(() {
          _budget!.expenseCategories[catIndex].items.removeAt(itemIndex);
        });
        _saveBudget();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            // Nombre
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.isMonthlyExpense)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '📆 ${item.paymentDate != null ? "${item.paymentDate!.day}/${item.paymentDate!.month}" : "-"} • Meta: \$${item.totalMonthlyAmount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            // Fijo checkbox
            SizedBox(
              width: 32,
              child: Transform.scale(
                scale: 0.8,
                child: Checkbox(
                  value: item.isFixed,
                  onChanged: (val) {
                    setState(() => item.isFixed = val ?? false);
                    _saveBudget();
                  },
                  activeColor: colors[1],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
            // Tarjeta checkbox
            SizedBox(
              width: 32,
              child: Transform.scale(
                scale: 0.8,
                child: Checkbox(
                  value: item.isPaidWithCard,
                  onChanged: (val) {
                    setState(() => item.isPaidWithCard = val ?? false);
                    _saveBudget();
                  },
                  activeColor: colors[1],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
            // Hormiga
            SizedBox(
              width: 32,
              child: Transform.scale(
                scale: 0.8,
                child: Checkbox(
                  value: item.isAntExpense,
                  onChanged: (val) {
                    setState(() => item.isAntExpense = val ?? false);
                    _saveBudget();
                  },
                  activeColor: colors[1],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
            // Monto
            SizedBox(
              width: 64,
              child: GestureDetector(
                onTap: () => _editAmount(catIndex, itemIndex, item),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.amount > 0
                        ? colors[1].withOpacity(0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.amount > 0
                        ? '\$${item.amount.toStringAsFixed(0)}'
                        : '-',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: item.amount > 0
                          ? AppColors.textPrimary
                          : AppColors.textLight,
                    ),
                  ),
                ),
              ),
            ),
            // Borrar
            SizedBox(
              width: 28,
              child: IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                color: AppColors.coral,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  setState(() {
                    _budget!.expenseCategories[catIndex].items.removeAt(itemIndex);
                  });
                  _saveBudget();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── DIÁLOGOS ──

  void _showAddIncomeDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    String selectedType = 'Fijo';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(
              24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Nuevo ingreso 💰',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),

              // Nombre
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre del ingreso',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.lavenderLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.lavenderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.lavender, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Tipo
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setModalState(() => selectedType = 'Fijo'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: selectedType == 'Fijo'
                              ? AppColors.lavender.withOpacity(0.2)
                              : AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selectedType == 'Fijo'
                                ? AppColors.lavender
                                : AppColors.lavenderLight,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '📌 Fijo',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: selectedType == 'Fijo'
                                  ? AppColors.lavenderDark
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setModalState(() => selectedType = 'Variable'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: selectedType == 'Variable'
                              ? AppColors.peach.withOpacity(0.2)
                              : AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selectedType == 'Variable'
                                ? AppColors.peach
                                : AppColors.lavenderLight,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '🔄 Variable',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: selectedType == 'Variable'
                                  ? const Color(0xFFD4854A)
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Monto
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Monto semanal',
                  prefixText: '\$ ',
                  prefixStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.lavender,
                    fontSize: 18,
                  ),
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.lavenderLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.lavenderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.lavender, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Botón guardar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mint,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    if (nameController.text.isNotEmpty &&
                        amountController.text.isNotEmpty) {
                      final income = IncomeItem(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameController.text,
                        type: selectedType,
                        amount: double.tryParse(amountController.text) ?? 0,
                      );
                      setState(() => _budget!.incomes.add(income));
                      _saveBudget();
                      Navigator.pop(context);
                    }
                  },
                  child: const Text(
                    'Agregar ingreso ✨',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddExpenseDialog(int categoryIndex) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final totalAmountController = TextEditingController();
    
    bool isFixed = false;
    bool isPaidWithCard = false;
    bool isMonthly = false;
    DateTime? selectedDate;

    final category = _budget!.expenseCategories[categoryIndex];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(
              24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Nuevo gasto ${category.emoji} ${category.name}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),

              // Frecuencia
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setModalState(() => isMonthly = false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !isMonthly
                              ? AppColors.lavender.withOpacity(0.2)
                              : AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: !isMonthly
                                ? AppColors.lavender
                                : AppColors.lavenderLight,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '📅 Semanal',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: !isMonthly
                                  ? AppColors.lavenderDark
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setModalState(() => isMonthly = true),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isMonthly
                              ? AppColors.skyBlue.withOpacity(0.2)
                              : AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isMonthly
                                ? AppColors.skyBlue
                                : AppColors.lavenderLight,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '🗓️ Mensual',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isMonthly
                                  ? const Color(0xFF3D7A9E)
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Nombre
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre del gasto',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.lavenderLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.lavenderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.lavender, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              if (isMonthly) ...[
                // Fecha de pago y Monto Total
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: AppColors.lavender,
                                    onPrimary: Colors.white,
                                    onSurface: AppColors.textPrimary,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (date != null) {
                            setModalState(() => selectedDate = date);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.lavenderLight),
                          ),
                          child: Text(
                            selectedDate == null
                                ? 'Fecha de pago'
                                : 'Pago: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                            style: TextStyle(
                              color: selectedDate == null
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: totalAmountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          labelText: 'Monto total',
                          prefixText: '\$ ',
                          prefixStyle: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.skyBlue,
                            fontSize: 16,
                          ),
                          labelStyle: TextStyle(color: AppColors.textSecondary),
                          filled: true,
                          fillColor: AppColors.cardBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: AppColors.lavenderLight),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: AppColors.lavenderLight),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: AppColors.lavender, width: 2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],

              // Monto Semanal (Abono)
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: isMonthly ? 'Abono semanal' : 'Monto semanal',
                  prefixText: '\$ ',
                  prefixStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.lavender,
                    fontSize: 18,
                  ),
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.lavenderLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.lavenderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.lavender, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Opciones
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setModalState(() => isFixed = !isFixed),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isFixed
                              ? AppColors.peach.withOpacity(0.2)
                              : AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isFixed
                                ? AppColors.peach
                                : AppColors.lavenderLight,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '📌 Gasto fijo',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: isFixed
                                  ? const Color(0xFFD4854A)
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setModalState(
                          () => isPaidWithCard = !isPaidWithCard),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isPaidWithCard
                              ? AppColors.mint.withOpacity(0.2)
                              : AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isPaidWithCard
                                ? AppColors.mint
                                : AppColors.lavenderLight,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '💳 Con tarjeta',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: isPaidWithCard
                                  ? const Color(0xFF2E7D4F)
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Botón guardar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lavender,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    if (nameController.text.isNotEmpty) {
                      final expense = ExpenseItem(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameController.text,
                        isFixed: isFixed,
                        isPaidWithCard: isPaidWithCard,
                        isMonthlyExpense: isMonthly,
                        paymentDate: selectedDate,
                        totalMonthlyAmount: double.tryParse(totalAmountController.text) ?? 0,
                        amount: double.tryParse(amountController.text) ?? 0,
                      );
                      setState(() {
                        _budget!.expenseCategories[categoryIndex].items
                            .add(expense);
                      });
                      _saveBudget();
                      Navigator.pop(context);
                    }
                  },
                  child: const Text(
                    'Agregar gasto ✨',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editAmount(int catIndex, int itemIndex, ExpenseItem item) {
    final controller =
        TextEditingController(text: item.amount.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.background,
        title: Text(
          'Monto de "${item.name}"',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontSize: 16,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            prefixText: '\$ ',
            prefixStyle: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.lavender,
            ),
            filled: true,
            fillColor: AppColors.cardBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.lavenderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.lavender, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lavender,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            onPressed: () {
              setState(() {
                item.amount =
                    double.tryParse(controller.text) ?? 0;
              });
              _saveBudget();
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
