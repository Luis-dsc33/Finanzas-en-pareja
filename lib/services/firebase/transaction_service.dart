import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/transaction_models.dart';

/// Servicio para gestionar transacciones reales (gastos registrados).
/// Se guardan por semana usando el mismo weekId que BudgetService.
class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'transactions';

  /// Obtiene las transacciones de una semana.
  Future<WeeklyTransactions?> getWeeklyTransactions(String weekId) async {
    final doc = await _firestore.collection(_collection).doc(weekId).get();
    if (doc.exists && doc.data() != null) {
      return WeeklyTransactions.fromMap(doc.data()!);
    }
    return null;
  }

  /// Guarda/actualiza las transacciones de una semana.
  Future<void> saveWeeklyTransactions(WeeklyTransactions data) async {
    await _firestore
        .collection(_collection)
        .doc(data.weekId)
        .set(data.toMap());
  }

  /// Agrega una transacción a una semana.
  Future<void> addTransaction(String weekId, TransactionItem item) async {
    WeeklyTransactions? weekly = await getWeeklyTransactions(weekId);
    weekly ??= WeeklyTransactions(weekId: weekId);
    weekly.transactions.add(item);
    await saveWeeklyTransactions(weekly);
  }

  /// Elimina una transacción de una semana.
  Future<void> deleteTransaction(String weekId, String transactionId) async {
    final weekly = await getWeeklyTransactions(weekId);
    if (weekly != null) {
      weekly.transactions.removeWhere((t) => t.id == transactionId);
      await saveWeeklyTransactions(weekly);
    }
  }

  /// Escucha cambios en tiempo real de una semana.
  Stream<WeeklyTransactions?> watchWeeklyTransactions(String weekId) {
    return _firestore
        .collection(_collection)
        .doc(weekId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return WeeklyTransactions.fromMap(doc.data()!);
      }
      return null;
    });
  }

  /// Obtiene transacciones de múltiples semanas (para vista mensual).
  Future<List<TransactionItem>> getTransactionsForWeeks(
      List<String> weekIds) async {
    final allTransactions = <TransactionItem>[];
    for (final weekId in weekIds) {
      final weekly = await getWeeklyTransactions(weekId);
      if (weekly != null) {
        allTransactions.addAll(weekly.transactions);
      }
    }
    allTransactions.sort((a, b) => b.date.compareTo(a.date));
    return allTransactions;
  }
  /// Obtiene transacciones de múltiples semanas (para vista mensual) como un Stream.
  Stream<List<TransactionItem>> watchTransactionsForWeeks(List<String> weekIds) {
    if (weekIds.isEmpty) return Stream.value([]);
    
    // Escuchar múltiples documentos combinando sus streams
    final streams = weekIds.map((id) => watchWeeklyTransactions(id));
    
    // Rx.combineLatest no está disponible sin rxdart, así que hacemos una solución con StreamGroup o manual
    // Dado que queremos evitar dependencias extra si no las hay, devolvemos un mapeo asíncrono manual
    // Pero lo más sencillo es un StreamController
    // Como simplificación para no usar rxdart, por ahora podemos usar una suscripción manual en la pantalla,
    // o hacer un snapshot. Pero lo mejor será que la pantalla mensual recargue si el de la semana actual cambia,
    // o usar rxdart si está. Revisemos si podemos usar rxdart.
    // Como alternativa sin rxdart:
    return _firestore
        .collection(_collection)
        .where(FieldPath.documentId, whereIn: weekIds)
        .snapshots()
        .map((querySnapshot) {
      final allTransactions = <TransactionItem>[];
      for (final doc in querySnapshot.docs) {
        if (doc.data() != null) {
          final weekly = WeeklyTransactions.fromMap(doc.data() as Map<String, dynamic>);
          allTransactions.addAll(weekly.transactions);
        }
      }
      allTransactions.sort((a, b) => b.date.compareTo(a.date));
      return allTransactions;
    });
  }
}
