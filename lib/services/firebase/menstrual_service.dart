import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/menstrual_models.dart';

/// Servicio para gestionar datos del calendario menstrual en Firestore.
/// Solo un documento único "data" dentro de la colección "menstrual".
class MenstrualService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'menstrual';
  static const String _docId = 'data';

  /// Obtiene los datos del calendario (one-shot).
  Future<MenstrualData?> getData() async {
    final doc = await _firestore.collection(_collection).doc(_docId).get();
    if (doc.exists && doc.data() != null) {
      return MenstrualData.fromMap(doc.data()!);
    }
    return null;
  }

  /// Escucha cambios en tiempo real del calendario menstrual.
  Stream<MenstrualData?> watchData() {
    return _firestore
        .collection(_collection)
        .doc(_docId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return MenstrualData.fromMap(doc.data()!);
      }
      return null;
    });
  }

  /// Guarda todos los datos del calendario.
  Future<void> saveData(MenstrualData data) async {
    await _firestore.collection(_collection).doc(_docId).set(data.toMap());
  }

  /// Agrega un nuevo ciclo.
  Future<void> addCycle(MenstrualCycle cycle) async {
    final data = await getData() ?? MenstrualData();
    data.cycles.add(cycle);
    await saveData(data);
  }

  /// Finaliza un ciclo (pone endDate).
  Future<void> endCycle(String cycleId, DateTime endDate) async {
    final data = await getData();
    if (data == null) return;
    final index = data.cycles.indexWhere((c) => c.id == cycleId);
    if (index >= 0) {
      data.cycles[index].endDate = endDate;
      await saveData(data);
    }
  }

  /// Elimina un ciclo.
  Future<void> deleteCycle(String cycleId) async {
    final data = await getData();
    if (data == null) return;
    data.cycles.removeWhere((c) => c.id == cycleId);
    await saveData(data);
  }

  /// Toggle de corazón en un día.
  Future<void> toggleHeart(DateTime date) async {
    final data = await getData() ?? MenstrualData();
    final key = _dateToKey(date);
    final index = data.logs.indexWhere((l) => l.dateKey == key);
    if (index >= 0) {
      data.logs[index].hasHeart = !data.logs[index].hasHeart;
      // Si ya no tiene nada, eliminar el log
      if (!data.logs[index].hasHeart && data.logs[index].symptoms.isEmpty) {
        data.logs.removeAt(index);
      }
    } else {
      data.logs.add(DailyLog(dateKey: key, hasHeart: true));
    }
    await saveData(data);
  }

  static String _dateToKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
