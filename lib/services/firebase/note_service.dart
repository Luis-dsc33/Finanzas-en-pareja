import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/note_models.dart';

class NoteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'notes';

  Stream<List<NoteItem>> watchNotes(String currentUserId) {
    return _firestore.collection(_collection).snapshots().map((snapshot) {
      final notes = snapshot.docs.map((doc) => NoteItem.fromMap(doc.data())).toList();
      // Filtrar para ver solo mis notas personales y todas las grupales
      return notes.where((note) {
        if (note.type == NoteType.group) return true;
        return note.authorId == currentUserId;
      }).toList();
    });
  }

  Future<void> saveNote(NoteItem note) async {
    await _firestore.collection(_collection).doc(note.id).set(note.toMap());
  }

  Future<void> deleteNote(String noteId) async {
    await _firestore.collection(_collection).doc(noteId).delete();
  }
}
