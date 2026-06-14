import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/goal_models.dart';

/// Servicio para gestionar Metas y Deudas en Firebase.
/// Almacenaremos las metas y deudas de la pareja en un solo documento para simplificar.
class GoalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'goals';
  static const String _docId = 'couple_goals'; // Un solo doc para toda la pareja

  /// Obtiene los datos de metas y deudas.
  Future<FinancialGoalsData?> getGoalsData() async {
    final doc = await _firestore.collection(_collection).doc(_docId).get();
    if (doc.exists && doc.data() != null) {
      return FinancialGoalsData.fromMap(doc.data()!);
    }
    return null;
  }

  /// Guarda/actualiza todo el documento de metas y deudas.
  Future<void> saveGoalsData(FinancialGoalsData data) async {
    await _firestore.collection(_collection).doc(_docId).set(data.toMap());
  }

  /// Escucha cambios en tiempo real del documento.
  Stream<FinancialGoalsData> watchGoalsData() {
    return _firestore.collection(_collection).doc(_docId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return FinancialGoalsData.fromMap(doc.data()!);
      }
      return FinancialGoalsData(); // Devuelve vacío si no existe
    });
  }

  // --- MÉTODOS AUXILIARES ---

  /// Agrega o actualiza una Meta de Ahorro.
  Future<void> saveSavingsGoal(SavingsGoal goal) async {
    FinancialGoalsData? data = await getGoalsData();
    data ??= FinancialGoalsData();

    final index = data.savingsGoals.indexWhere((g) => g.id == goal.id);
    if (index >= 0) {
      data.savingsGoals[index] = goal;
    } else {
      data.savingsGoals.add(goal);
    }
    await saveGoalsData(data);
  }

  /// Elimina una Meta de Ahorro.
  Future<void> deleteSavingsGoal(String goalId) async {
    FinancialGoalsData? data = await getGoalsData();
    if (data != null) {
      data.savingsGoals.removeWhere((g) => g.id == goalId);
      await saveGoalsData(data);
    }
  }

  /// Agrega o actualiza una Deuda.
  Future<void> saveDebt(DebtItem debt) async {
    FinancialGoalsData? data = await getGoalsData();
    data ??= FinancialGoalsData();

    final index = data.debts.indexWhere((d) => d.id == debt.id);
    if (index >= 0) {
      data.debts[index] = debt;
    } else {
      data.debts.add(debt);
    }
    await saveGoalsData(data);
  }

  /// Elimina una Deuda.
  Future<void> deleteDebt(String debtId) async {
    FinancialGoalsData? data = await getGoalsData();
    if (data != null) {
      data.debts.removeWhere((d) => d.id == debtId);
      await saveGoalsData(data);
    }
  }
}
