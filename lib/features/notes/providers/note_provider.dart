import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/note_models.dart';
import '../../../services/firebase/note_service.dart';

final noteServiceProvider = Provider<NoteService>((ref) {
  return NoteService();
});

final notesProvider = StreamProvider<List<NoteItem>>((ref) {
  final service = ref.watch(noteServiceProvider);
  final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  return service.watchNotes(userId);
});
