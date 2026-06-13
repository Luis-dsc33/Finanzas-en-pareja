import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/budget_models.dart';

/// Servicio CRUD para presupuestos semanales en Firebase Firestore.
///
/// Estructura Firestore:
/// budgets/{weekId} → BudgetData (documento completo del presupuesto semanal)
class BudgetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _collection = 'budgets';

  /// Obtiene el presupuesto de una semana específica.
  /// Si no existe, retorna null.
  Future<BudgetData?> getBudget(String weekId) async {
    final doc = await _firestore.collection(_collection).doc(weekId).get();
    if (doc.exists && doc.data() != null) {
      return BudgetData.fromMap(doc.data()!);
    }
    return null;
  }

  /// Guarda o actualiza el presupuesto completo de una semana.
  Future<void> saveBudget(BudgetData budget) async {
    await _firestore
        .collection(_collection)
        .doc(budget.weekId)
        .set(budget.toMap(), SetOptions(merge: true));
  }

  /// Escucha cambios en tiempo real del presupuesto de una semana.
  /// Útil para sincronización entre Miri y Luisito.
  Stream<BudgetData?> watchBudget(String weekId) {
    return _firestore
        .collection(_collection)
        .doc(weekId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return BudgetData.fromMap(doc.data()!);
      }
      return null;
    });
  }

  /// Crea un presupuesto nuevo para una semana (vacío con categorías por defecto).
  Future<BudgetData> createEmptyBudget(String weekId) async {
    final budget = BudgetData(weekId: weekId);
    await saveBudget(budget);
    return budget;
  }

  Future<BudgetData?> duplicateFromWeek(
      String sourceWeekId, String targetWeekId) async {
    final source = await getBudget(sourceWeekId);
    if (source != null) {
      final newBudget = BudgetData(
        weekId: targetWeekId,
        incomes: source.incomes.where((i) => i.type == 'Fijo').toList(),
        savingsPercentage: source.savingsPercentage,
        expenseCategories: source.expenseCategories,
      );
      await saveBudget(newBudget);
      return newBudget;
    }
    return null;
  }

  /// Elimina el presupuesto de una semana.
  Future<void> deleteBudget(String weekId) async {
    await _firestore.collection(_collection).doc(weekId).delete();
  }

  // ─── Helpers para Week ID ───

  /// Obtiene el weekId de la semana actual
  static String getCurrentWeekId() {
    return getWeekIdForDate(DateTime.now());
  }

  /// Obtiene el weekId para una fecha dada (El domingo más reciente)
  static String getWeekIdForDate(DateTime date) {
    // date.weekday: 1=Lunes, ..., 7=Domingo
    final int daysSinceSunday = date.weekday % 7;
    final DateTime startOfWeek = date.subtract(Duration(days: daysSinceSunday));
    return '${startOfWeek.year}-${startOfWeek.month.toString().padLeft(2, '0')}-${startOfWeek.day.toString().padLeft(2, '0')}';
  }

  /// Obtiene el weekId de la semana anterior
  static String getPreviousWeekId(String currentWeekId) {
    if (currentWeekId.contains('-W')) {
      final parts = currentWeekId.split('-W');
      int year = int.parse(parts[0]);
      int week = int.parse(parts[1]);
      week--;
      if (week < 1) {
        year--;
        week = _getLastWeekOfYear(year);
      }
      return '$year-W${week.toString().padLeft(2, '0')}';
    }
    
    final DateTime currentStart = DateTime.parse(currentWeekId);
    final DateTime prevStart = currentStart.subtract(const Duration(days: 7));
    return '${prevStart.year}-${prevStart.month.toString().padLeft(2, '0')}-${prevStart.day.toString().padLeft(2, '0')}';
  }

  /// Obtiene el weekId de la semana siguiente
  static String getNextWeekId(String currentWeekId) {
    if (currentWeekId.contains('-W')) {
      final parts = currentWeekId.split('-W');
      int year = int.parse(parts[0]);
      int week = int.parse(parts[1]);
      week++;
      if (week > _getLastWeekOfYear(year)) {
        year++;
        week = 1;
      }
      return '$year-W${week.toString().padLeft(2, '0')}';
    }
    
    final DateTime currentStart = DateTime.parse(currentWeekId);
    final DateTime nextStart = currentStart.add(const Duration(days: 7));
    return '${nextStart.year}-${nextStart.month.toString().padLeft(2, '0')}-${nextStart.day.toString().padLeft(2, '0')}';
  }

  /// Obtiene las fechas de inicio y fin de una semana
  static (DateTime, DateTime) getWeekDateRange(String weekId) {
    if (weekId.contains('-W')) {
      final parts = weekId.split('-W');
      int year = int.parse(parts[0]);
      int week = int.parse(parts[1]);
      final jan1 = DateTime(year, 1, 1);
      final dayOfWeek = jan1.weekday;
      final firstMonday = jan1.add(Duration(days: (8 - dayOfWeek) % 7));
      final start = firstMonday.add(Duration(days: (week - 1) * 7));
      final end = start.add(const Duration(days: 6));
      return (start, end);
    }
    
    final start = DateTime.parse(weekId);
    final end = start.add(const Duration(days: 6));
    return (start, end);
  }

  /// Formatea las fechas de una semana para mostrar
  static String formatWeekRange(String weekId) {
    final (start, end) = getWeekDateRange(weekId);
    const months = [
      '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${start.day} ${months[start.month]} - ${end.day} ${months[end.month]} ${end.year}';
  }

  static int _getLastWeekOfYear(int year) {
    final dec28 = DateTime(year, 12, 28);
    final dayOfYear = dec28.difference(DateTime(year, 1, 1)).inDays;
    return ((dayOfYear - dec28.weekday + 10) / 7).floor();
  }
}
