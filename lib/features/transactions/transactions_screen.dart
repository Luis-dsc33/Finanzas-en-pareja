import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/transaction_models.dart';
import '../../models/budget_models.dart';
import '../../services/firebase/transaction_service.dart';
import '../../services/firebase/budget_service.dart';
import '../../main.dart'; // Para AppColors

// ─────────────────────────────────────────────
// PANTALLA TRACKER DE GASTOS SEMANALES
// ─────────────────────────────────────────────

enum ViewMode { daily, weekly, monthly }

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TransactionService _transactionService = TransactionService();
  final BudgetService _budgetService = BudgetService();

  late String _currentWeekId;
  WeeklyTransactions? _weeklyTransactions;
  BudgetData? _budget;
  bool _isLoading = true;
  ViewMode _viewMode = ViewMode.weekly;
  String? _selectedCategory; // null = Todos

  // Para vista mensual: transacciones de ~4 semanas
  List<TransactionItem> _monthlyTransactions = [];

  // Suscripciones para actualización en tiempo real
  StreamSubscription<BudgetData?>? _budgetSub;
  StreamSubscription<WeeklyTransactions?>? _weeklySub;
  StreamSubscription<List<TransactionItem>>? _monthlySub;

  @override
  void initState() {
    super.initState();
    _currentWeekId = BudgetService.getCurrentWeekId();
    _startListening();
  }

  @override
  void dispose() {
    _budgetSub?.cancel();
    _weeklySub?.cancel();
    _monthlySub?.cancel();
    super.dispose();
  }

  void _startListening() {
    _budgetSub?.cancel();
    _weeklySub?.cancel();
    _monthlySub?.cancel();

    setState(() => _isLoading = true);

    // Escuchar el presupuesto
    _budgetSub = _budgetService.watchBudget(_currentWeekId).listen((budget) {
      if (mounted) {
        setState(() => _budget = budget ?? BudgetData(weekId: _currentWeekId));
      }
    });

    // Escuchar transacciones
    if (_viewMode == ViewMode.monthly) {
      final weekIds = <String>[];
      var wId = _currentWeekId;
      for (int i = 0; i < 4; i++) {
        weekIds.add(wId);
        wId = BudgetService.getPreviousWeekId(wId);
      }
      _monthlySub = _transactionService.watchTransactionsForWeeks(weekIds).listen((transactions) {
        if (mounted) {
          setState(() {
            _monthlyTransactions = transactions;
            _isLoading = false;
          });
        }
      }, onError: (e) {
        if (mounted) setState(() => _isLoading = false);
      });
    } else {
      _weeklySub = _transactionService.watchWeeklyTransactions(_currentWeekId).listen((weekly) {
        if (mounted) {
          setState(() {
            _weeklyTransactions = weekly ?? WeeklyTransactions(weekId: _currentWeekId);
            _isLoading = false;
          });
        }
      }, onError: (e) {
        if (mounted) setState(() => _isLoading = false);
      });
    }
  }

  void _navigateWeek(int direction) {
    setState(() {
      _currentWeekId = direction > 0
          ? BudgetService.getNextWeekId(_currentWeekId)
          : BudgetService.getPreviousWeekId(_currentWeekId);
    });
    _startListening();
  }

  List<TransactionItem> get _activeTransactions {
    List<TransactionItem> items;

    if (_viewMode == ViewMode.monthly) {
      items = List.from(_monthlyTransactions);
    } else if (_viewMode == ViewMode.daily) {
      final now = DateTime.now();
      items = (_weeklyTransactions?.transactions ?? [])
          .where((t) =>
              t.date.year == now.year &&
              t.date.month == now.month &&
              t.date.day == now.day)
          .toList();
    } else {
      items = _weeklyTransactions?.transactions ?? [];
    }

    // Filtrar por categoría si se seleccionó una
    if (_selectedCategory != null) {
      items = items.where((t) => t.categoryName == _selectedCategory).toList();
    }

    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  double get _totalSpentFiltered =>
      _activeTransactions.fold(0, (sum, t) => sum + t.amount);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.lavender))
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
                          'Registro de gastos 📝',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Controla lo que realmente gastas',
                          style: TextStyle(
                              fontSize: 14, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),

                        // Toggle de vista: Diario / Semanal / Mensual
                        _buildViewModeToggle(),
                        const SizedBox(height: 16),

                        // Navegador de semana (solo en semanal/diario)
                        if (_viewMode != ViewMode.monthly)
                          _buildWeekNavigator(),
                        if (_viewMode == ViewMode.monthly)
                          _buildMonthHeader(),
                        const SizedBox(height: 16),

                        // Tarjeta Resumen: Presupuestado vs Gastado
                        _buildComparisonCard(),
                        const SizedBox(height: 16),

                        // Barras de progreso por categoría
                        _buildCategoryProgressSection(),
                        const SizedBox(height: 16),

                        // Filtro por categoría
                        _buildCategoryFilter(),
                        const SizedBox(height: 12),

                        // Título de lista
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _viewMode == ViewMode.daily
                                  ? 'Gastos de hoy'
                                  : _viewMode == ViewMode.monthly
                                      ? 'Gastos del mes'
                                      : 'Gastos de la semana',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${_activeTransactions.length} registros',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),

                // Lista de transacciones
                _activeTransactions.isEmpty
                    ? SliverToBoxAdapter(
                        child: _buildEmptyState(),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final grouped = _groupByDay(_activeTransactions);
                              final entries = grouped.entries.toList();

                              int itemIndex = 0;
                              for (final entry in entries) {
                                // Date header
                                if (itemIndex == index) {
                                  return _buildDateHeader(entry.key);
                                }
                                itemIndex++;

                                // Transaction items
                                for (final transaction in entry.value) {
                                  if (itemIndex == index) {
                                    return _buildTransactionTile(transaction);
                                  }
                                  itemIndex++;
                                }
                              }
                              return const SizedBox();
                            },
                            childCount: _calculateListCount(),
                          ),
                        ),
                      ),
              ],
            ),
    );
  }

  int _calculateListCount() {
    final grouped = _groupByDay(_activeTransactions);
    int count = 0;
    for (final entry in grouped.entries) {
      count++; // header
      count += entry.value.length; // items
    }
    return count;
  }

  Map<DateTime, List<TransactionItem>> _groupByDay(
      List<TransactionItem> items) {
    final map = <DateTime, List<TransactionItem>>{};
    for (final t in items) {
      final key = DateTime(t.date.year, t.date.month, t.date.day);
      map.putIfAbsent(key, () => []).add(t);
    }
    final sorted = Map.fromEntries(
      map.entries.toList()..sort((a, b) => b.key.compareTo(a.key)),
    );
    return sorted;
  }

  // ── TOGGLE DE VISTA ──
  Widget _buildViewModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildViewTab('📅 Diario', ViewMode.daily),
          _buildViewTab('📊 Semanal', ViewMode.weekly),
          _buildViewTab('🗓️ Mensual', ViewMode.monthly),
        ],
      ),
    );
  }

  Widget _buildViewTab(String label, ViewMode mode) {
    final isSelected = _viewMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _viewMode = mode);
          _startListening();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.pink.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
                color:
                    isSelected ? AppColors.pink : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── NAVEGADOR DE SEMANA ──
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
            color: AppColors.pink,
            iconSize: 28,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  _viewMode == ViewMode.daily ? 'Hoy' : _currentWeekId,
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
            color: AppColors.pink,
            iconSize: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthHeader() {
    const months = [
      '',
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    final now = DateTime.now();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
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
      child: Center(
        child: Text(
          '${months[now.month]} ${now.year}',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  // ── TARJETA COMPARATIVA ──
  Widget _buildComparisonCard() {
    double budgeted = 0;
    double spent = 0;

    if (_viewMode == ViewMode.monthly) {
      // Mensual: Suma de sueldos fijos de la semana actual multiplicado por 4 (aprox de un mes)
      final fixedIncomes = _budget?.incomes
              .where((i) => i.type == 'Fijo')
              .fold(0.0, (sum, i) => sum + i.amount) ?? 0.0;
      budgeted = fixedIncomes * 4;
      spent = _monthlyTransactions.fold(0.0, (sum, t) => sum + t.amount);
    } else if (_viewMode == ViewMode.daily) {
      budgeted = _budget?.totalExpenses ?? 0;
      spent = (_weeklyTransactions?.todayTransactions ?? [])
          .fold(0.0, (sum, t) => sum + t.amount);
    } else {
      budgeted = _budget?.totalExpenses ?? 0;
      spent = _weeklyTransactions?.totalSpent ?? 0;
    }

    final progress = budgeted > 0 ? (spent / budgeted).clamp(0.0, 1.5) : 0.0;
    final isOverBudget = spent > budgeted && budgeted > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isOverBudget
              ? [
                  const Color(0xFFFFADAD),
                  const Color(0xFFFFD6A5),
                ]
              : [
                  const Color(0xFFF2B5D4),
                  const Color(0xFFCBB6F0),
                  const Color(0xFFA8D8EA),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isOverBudget ? AppColors.coral : AppColors.pink)
                .withOpacity(0.25),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Presupuestado',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '\$${budgeted.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isOverBudget ? '⚠️ Excedido' : '✅ En control',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gastado',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '\$${spent.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Restante',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '\$${(budgeted - spent).toStringAsFixed(0)}',
                    style: TextStyle(
                      color: isOverBudget
                          ? const Color(0xFFFFCDD2)
                          : Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.toDouble().clamp(0.0, 1.0),
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation(
                isOverBudget ? const Color(0xFFFF6B6B) : Colors.white,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            budgeted > 0
                ? '${(progress * 100).toStringAsFixed(0)}% del presupuesto'
                : 'Sin presupuesto definido',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ── BARRAS DE PROGRESO POR CATEGORÍA ──
  Widget _buildCategoryProgressSection() {
    if (_budget == null) return const SizedBox();

    final categories = _budget!.expenseCategories
        .where((c) => c.total > 0)
        .toList();

    if (categories.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
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
          const Text(
            'Progreso por categoría',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          ...categories.map((cat) {
            final spent = _viewMode == ViewMode.monthly
                ? _monthlyTransactions
                    .where((t) => t.categoryName == cat.name)
                    .fold(0.0, (sum, t) => sum + t.amount)
                : (_weeklyTransactions?.totalByCategory(cat.name) ?? 0);
            final budgeted = cat.total;
            final progress =
                budgeted > 0 ? (spent / budgeted).clamp(0.0, 1.5) : 0.0;
            final isOver = spent > budgeted && budgeted > 0;

            Color barColor;
            if (isOver) {
              barColor = AppColors.coral;
            } else if (progress > 0.75) {
              barColor = AppColors.peach;
            } else {
              barColor = AppColors.mint;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${cat.emoji} ${cat.name}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '\$${spent.toStringAsFixed(0)} / \$${budgeted.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isOver
                              ? AppColors.coral
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress.toDouble().clamp(0.0, 1.0),
                      backgroundColor: barColor.withOpacity(0.15),
                      valueColor: AlwaysStoppedAnimation(barColor),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── FILTRO POR CATEGORÍA ──
  Widget _buildCategoryFilter() {
    final categories = _budget?.expenseCategories ?? [];

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('Todos', null, AppColors.lavender),
          const SizedBox(width: 8),
          ...categories.map((cat) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildFilterChip(
                  '${cat.emoji} ${cat.name}',
                  cat.name,
                  AppColors.pink,
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
      String label, String? categoryName, Color color) {
    final isSelected = _selectedCategory == categoryName;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = categoryName),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.2)
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // ── ESTADO VACÍO ──
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        children: [
          const Text('🧾', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text(
            'Sin gastos registrados',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Presiona el botón + para agregar tu primer gasto',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── HEADER DE FECHA ──
  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    String label;
    if (date == today) {
      label = 'Hoy';
    } else if (date == yesterday) {
      label = 'Ayer';
    } else {
      const days = [
        '',
        'Lunes',
        'Martes',
        'Miércoles',
        'Jueves',
        'Viernes',
        'Sábado',
        'Domingo'
      ];
      const months = [
        '',
        'Ene',
        'Feb',
        'Mar',
        'Abr',
        'May',
        'Jun',
        'Jul',
        'Ago',
        'Sep',
        'Oct',
        'Nov',
        'Dic'
      ];
      label =
          '${days[date.weekday]} ${date.day} ${months[date.month]}';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  // ── TILE DE TRANSACCIÓN ──
  Widget _buildTransactionTile(TransactionItem transaction) {
    // Color según categoría
    final catIndex = (_budget?.expenseCategories ?? [])
        .indexWhere((c) => c.name == transaction.categoryName);
    final Color tileColor = catIndex >= 0
        ? [
            AppColors.skyBlue,
            AppColors.peach,
            AppColors.pink,
            AppColors.skyBlue,
            AppColors.lemon,
            AppColors.mint,
            AppColors.skyBlue,
            AppColors.mint,
            AppColors.lemon,
            AppColors.skyBlue,
            AppColors.peach,
            AppColors.lavender,
          ][catIndex % 12]
        : AppColors.textLight;

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.coral.withOpacity(0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_rounded,
            color: AppColors.coral, size: 22),
      ),
      onDismissed: (_) {
        _transactionService.deleteTransaction(
            _currentWeekId, transaction.id);
        setState(() {
          _weeklyTransactions?.transactions
              .removeWhere((t) => t.id == transaction.id);
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: tileColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(transaction.categoryEmoji,
                    style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        transaction.paidBy,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (transaction.isAntExpense) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.lemon.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '🐜',
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                      if (transaction.note != null &&
                          transaction.note!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '• ${transaction.note}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textLight,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '-\$${transaction.amount.toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                _transactionService.deleteTransaction(_currentWeekId, transaction.id);
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.coral.withOpacity(0.1),
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
  }
}
