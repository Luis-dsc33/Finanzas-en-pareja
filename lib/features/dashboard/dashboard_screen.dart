import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../main.dart'; // AppColors
import '../../services/firebase/auth_service.dart';
import '../../services/firebase/budget_service.dart';
import '../../services/firebase/transaction_service.dart';
import '../../services/firebase/menstrual_service.dart';
import '../../models/budget_models.dart';
import '../../models/transaction_models.dart';
import '../../models/menstrual_models.dart';
import '../../models/goal_models.dart';
import '../goals/providers/goal_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final BudgetService _budgetService = BudgetService();
  final TransactionService _transactionService = TransactionService();
  final MenstrualService _menstrualService = MenstrualService();

  bool _isLoading = true;

  // Datos
  BudgetData? _budget;
  List<TransactionItem> _monthlyTransactions = [];
  MenstrualData? _menstrualData;

  // Suscripciones
  StreamSubscription? _budgetSub;
  StreamSubscription? _transactionsSub;
  StreamSubscription? _menstrualSub;

  late String _currentWeekId;

  @override
  void initState() {
    super.initState();
    _currentWeekId = BudgetService.getCurrentWeekId();
    _startListening();
  }

  void _startListening() {
    setState(() => _isLoading = true);

    // 1. Escuchar presupuesto de esta semana (lo multiplicaremos por 4 para el mes)
    _budgetSub = _budgetService.watchBudget(_currentWeekId).listen((budget) {
      if (mounted) setState(() => _budget = budget);
    });

    // 2. Escuchar transacciones de las últimas 4 semanas
    final weekIds = <String>[];
    var wId = _currentWeekId;
    for (int i = 0; i < 4; i++) {
      weekIds.add(wId);
      wId = BudgetService.getPreviousWeekId(wId);
    }
    _transactionsSub = _transactionService.watchTransactionsForWeeks(weekIds).listen((transactions) {
      if (mounted) setState(() => _monthlyTransactions = transactions);
    });

    // 3. Escuchar datos menstruales
    _menstrualSub = _menstrualService.watchData().listen((data) {
      if (mounted) {
        setState(() {
          _menstrualData = data;
          _isLoading = false; // Asumimos que este es el último
        });
      }
    });
  }

  @override
  void dispose() {
    _budgetSub?.cancel();
    _transactionsSub?.cancel();
    _menstrualSub?.cancel();
    super.dispose();
  }

  // ── CÁLCULOS ──
  
  double get _expectedMonthlyFixedIncome {
    if (_budget == null) return 0;
    return _budget!.incomes.where((i) => i.type == 'Fijo').fold(0.0, (s, i) => s + i.amount) * 4;
  }

  double get _expectedMonthlyVariableIncome {
    if (_budget == null) return 0;
    return _budget!.incomes.where((i) => i.type == 'Variable').fold(0.0, (s, i) => s + i.amount) * 4;
  }

  double get _expectedMonthlyTotalIncome => _expectedMonthlyFixedIncome + _expectedMonthlyVariableIncome;

  double get _expectedMonthlyFixedExpenses {
    if (_budget == null) return 0;
    return _budget!.totalFixedExpenses * 4;
  }

  double get _expectedMonthlyVariableExpenses {
    if (_budget == null) return 0;
    return _budget!.totalVariableExpenses * 4;
  }

  double get _expectedMonthlyTotalExpenses => _expectedMonthlyFixedExpenses + _expectedMonthlyVariableExpenses;

  double get _availableEndOfMonth => _expectedMonthlyTotalIncome - _expectedMonthlyTotalExpenses;

  Map<String, double> get _expensesByCategory {
    final map = <String, double>{};
    for (var t in _monthlyTransactions) {
      map[t.categoryName] = (map[t.categoryName] ?? 0) + t.amount;
    }
    return map;
  }

  double get _actualTotalMonthlyExpenses => _monthlyTransactions.fold(0.0, (s, t) => s + t.amount);

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(goalsDataProvider);
    final goalsData = goalsAsync.value ?? FinancialGoalsData();

    if (_isLoading) {
      return const SafeArea(
        child: Center(child: CircularProgressIndicator(color: AppColors.skyBlue)),
      );
    }

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),

                  // A. Tarjetas Superiores
                  _buildTopCards(),
                  const SizedBox(height: 16),

                  // A.2 Progreso de Presupuesto
                  _buildBudgetProgressCard(),
                  const SizedBox(height: 20),

                  // B. Módulo del Ciclo Menstrual
                  _buildMenstrualWidget(),
                  const SizedBox(height: 20),

                  // C. Gastos Mensuales (Dona + Tabla)
                  _buildMonthlyExpensesChart(),
                  const SizedBox(height: 20),

                  // D. Ahorros y Deudas
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildSavingsList(goalsData.savingsGoals)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildDebtsList(goalsData.debts)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // E. Gráfico de Barras
                  _buildBarChart(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════
  Widget _buildHeader() {
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    final name = userEmail.contains('miri') ? 'Miri' : (userEmail.contains('luisito') ? 'Luisito' : 'Miri & Luisito');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hola $name 👋',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Mes actual estimado',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        _buildLogoutButton(),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.background,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Cerrar sesión', style: TextStyle(fontWeight: FontWeight.w700)),
            content: const Text('¿Estás seguro que deseas cerrar sesión?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.coral,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  await AuthService().signOut();
                },
                child: const Text('Salir'),
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.lavenderLight),
        ),
        child: Row(
          children: [
            _buildAvatar('M', AppColors.pink),
            Transform.translate(
              offset: const Offset(-8, 0),
              child: _buildAvatar('L', AppColors.lavender),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.logout_rounded, size: 16, color: AppColors.coral),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String letter, Color color) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.cardBackground, width: 2),
      ),
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // A. TARJETAS SUPERIORES
  // ═══════════════════════════════════════════
  Widget _buildTopCards() {
    return Column(
      children: [
        _buildSummaryCard(
          title: 'Ingresos Totales esperados al mes',
          total: _expectedMonthlyTotalIncome,
          leftSubTitle: 'Ingresos fijos',
          leftSubAmount: _expectedMonthlyFixedIncome,
          rightSubTitle: 'Ingresos variables',
          rightSubAmount: _expectedMonthlyVariableIncome,
          color: const Color(0xFF004D73), // Azul oscuro del Excel
        ),
        const SizedBox(height: 12),
        _buildSummaryCard(
          title: 'Total de Gastos esperados al mes',
          total: _expectedMonthlyTotalExpenses,
          leftSubTitle: 'Gastos fijos',
          leftSubAmount: _expectedMonthlyFixedExpenses,
          rightSubTitle: 'Gastos variables',
          rightSubAmount: _expectedMonthlyVariableExpenses,
          color: const Color(0xFF004D73),
        ),
        const SizedBox(height: 12),
        _buildSummaryCard(
          title: 'Disponible al final de mes',
          total: _availableEndOfMonth,
          leftSubTitle: '',
          leftSubAmount: 0,
          rightSubTitle: '',
          rightSubAmount: 0,
          color: const Color(0xFF004D73),
          singleValue: true,
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double total,
    required String leftSubTitle,
    required double leftSubAmount,
    required String rightSubTitle,
    required double rightSubAmount,
    required Color color,
    bool singleValue = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          // Total
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              '\$${total.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          // Divider
          if (!singleValue)
            Divider(height: 1, color: color.withOpacity(0.2)),
          // Subvalores
          if (!singleValue)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Text(leftSubTitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                      Text('\$${leftSubAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  Column(
                    children: [
                      Text(rightSubTitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                      Text('\$${rightSubAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // A.2 COMPARACIÓN DE PRESUPUESTO
  // ═══════════════════════════════════════════
  Widget _buildBudgetProgressCard() {
    final projected = _expectedMonthlyTotalExpenses;
    final actual = _actualTotalMonthlyExpenses;
    final percentage = projected > 0 ? (actual / projected) : 0.0;
    
    // Determinar el color según el progreso
    Color progressColor = AppColors.mint;
    if (percentage > 0.85 && percentage <= 1.0) {
      progressColor = AppColors.peach;
    } else if (percentage > 1.0) {
      progressColor = AppColors.coral;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lavenderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progreso del Presupuesto',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${(percentage * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: progressColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage > 1.0 ? 1.0 : percentage,
              backgroundColor: AppColors.lavenderLight.withOpacity(0.5),
              valueColor: AlwaysStoppedAnimation(progressColor),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Gastado', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                  Text('\$${actual.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Proyectado', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                  Text('\$${projected.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // B. MÓDULO CICLO MENSTRUAL
  // ═══════════════════════════════════════════
  Widget _buildMenstrualWidget() {
    final mData = _menstrualData ?? MenstrualData();
    if (mData.cycles.isEmpty) return const SizedBox();

    final phase = mData.currentPhase;
    final emoji = mData.currentPhaseEmoji;
    final daysUntil = mData.daysUntilNextPeriod;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.pink.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.pink.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.pink.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ciclo de Miri 🌸',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.pink),
                ),
                Text(
                  phase,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                if (daysUntil != null)
                  Text(
                    daysUntil <= 0 ? 'Periodo esperado hoy o ya en curso' : 'Próximo periodo en $daysUntil días',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // C. GASTOS MENSUALES (DONA + TABLA)
  // ═══════════════════════════════════════════
  Widget _buildMonthlyExpensesChart() {
    final expenses = _expensesByCategory;
    final total = _actualTotalMonthlyExpenses;

    // Colores para la dona
    final colors = [
      const Color(0xFF4FC3F7), // Azul claro
      const Color(0xFFFFB74D), // Naranja
      const Color(0xFF81C784), // Verde
      const Color(0xFFBA68C8), // Morado
      const Color(0xFFE57373), // Rojo claro
      const Color(0xFFFFF176), // Amarillo
    ];

    List<PieChartSectionData> sections = [];
    int colorIndex = 0;
    
    // Sort expenses by amount descending
    final sortedEntries = expenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (var entry in sortedEntries) {
      if (entry.value <= 0) continue;
      final percentage = (entry.value / total) * 100;
      sections.add(
        PieChartSectionData(
          color: colors[colorIndex % colors.length],
          value: entry.value,
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 40,
          titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      );
      colorIndex++;
    }

    if (sections.isEmpty) {
      sections.add(PieChartSectionData(
        color: AppColors.textLight.withOpacity(0.3),
        value: 100,
        title: '0%',
        radius: 40,
        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
      ));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lavenderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gastos Mensuales Reales', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 16),
          // Dona
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 50,
                sections: sections,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Tabla
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF004D73).withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                // Cabecera tabla
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF004D73),
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(7), topRight: Radius.circular(7)),
                  ),
                  child: const Row(
                    children: [
                      Expanded(flex: 2, child: Text('Gastos Mensuales', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12))),
                      Expanded(flex: 1, child: Text('%', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12))),
                      Expanded(flex: 1, child: Text('Monto', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12))),
                    ],
                  ),
                ),
                // Filas
                ...sortedEntries.map((e) {
                  final pct = total > 0 ? (e.value / total) * 100 : 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: Text('📌 ${e.key}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
                        Expanded(flex: 1, child: Text('${pct.toStringAsFixed(1)}%', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12))),
                        Expanded(flex: 1, child: Text('\$${e.value.toStringAsFixed(0)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                      ],
                    ),
                  );
                }).toList(),
                const Divider(height: 1),
                // Footer tabla
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      const Expanded(flex: 2, child: Text('Total de Gastos', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                      Expanded(flex: 2, child: Text('\$${total.toStringAsFixed(0)}', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textPrimary))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // D. AHORROS Y DEUDAS
  // ═══════════════════════════════════════════
  Widget _buildSavingsList(List<SavingsGoal> savings) {
    final total = savings.fold(0.0, (s, e) => s + e.monthlyTarget);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF004D73).withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF004D73),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(7), topRight: Radius.circular(7)),
            ),
            child: const Row(
              children: [
                Expanded(child: Text('Resumen de tus ahorros', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 10))),
                Text('Objetivo al mes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 10)),
              ],
            ),
          ),
          if (savings.isEmpty)
             const Padding(padding: EdgeInsets.all(8.0), child: Text('No hay metas', style: TextStyle(fontSize: 11))),
          ...savings.map((e) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Expanded(child: Text('${e.emoji} ${e.title}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                  Text(e.monthlyTarget > 0 ? '\$${e.monthlyTarget.toStringAsFixed(0)}' : '-', style: const TextStyle(fontSize: 11)),
                ],
              ),
            );
          }).toList(),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total de objetivos al mes', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 10)),
                const SizedBox(height: 2),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('\$${total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.skyBlue)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtsList(List<DebtItem> debts) {
    final total = debts.fold(0.0, (s, e) => s + e.balance);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF004D73).withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF004D73),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(7), topRight: Radius.circular(7)),
            ),
            child: const Row(
              children: [
                Expanded(child: Text('Resumen de tus deudas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 10))),
                Text('Deuda Actual', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 10)),
              ],
            ),
          ),
          if (debts.isEmpty)
             const Padding(padding: EdgeInsets.all(8.0), child: Text('No hay deudas', style: TextStyle(fontSize: 11))),
          ...debts.map((e) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Expanded(child: Text('💳 ${e.title}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                  Text(e.balance > 0 ? '\$${e.balance.toStringAsFixed(0)}' : '-', style: const TextStyle(fontSize: 11)),
                ],
              ),
            );
          }).toList(),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total de Deuda Actual', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 10)),
                const SizedBox(height: 2),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('\$${total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.skyBlue)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // E. GRÁFICO MES A MES
  // ═══════════════════════════════════════════
  Widget _buildBarChart() {
    // Datos de prueba imitando la gráfica del Excel
    final mockMonths = [
      {'name': 'Ene', 'val': 12074.0},
      {'name': 'Feb', 'val': 8074.0},
      {'name': 'Mar', 'val': 9773.0},
      {'name': 'Abr', 'val': 8824.0},
      {'name': 'May', 'val': 8404.0},
      {'name': 'Jun', 'val': _actualTotalMonthlyExpenses > 0 ? _actualTotalMonthlyExpenses : 7724.0},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lavenderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tus gastos mes a mes', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 15000,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            mockMonths[value.toInt()]['name'] as String,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox();
                        return Text('\$${(value/1000).toStringAsFixed(0)}k', style: const TextStyle(fontSize: 10));
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5000,
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: mockMonths.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value['val'] as double,
                        color: AppColors.skyBlue,
                        width: 20,
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                      )
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
