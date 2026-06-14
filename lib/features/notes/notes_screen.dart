import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../main.dart'; // AppColors
import 'providers/note_provider.dart';
import 'add_note_sheet.dart';
import '../../models/note_models.dart';

class NotesScreen extends ConsumerWidget {
  const NotesScreen({Key? key}) : super(key: key);

  void _showAddNoteSheet(BuildContext context, [NoteItem? note]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddNoteSheet(noteToEdit: note),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mis Notas 📝',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ideas, recordatorios y más',
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => _showAddNoteSheet(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.pink,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: notesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.pink)),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (notes) {
                if (notes.isEmpty) {
                  return const Center(
                    child: Text('Aún no tienes notas. ¡Crea una!', style: TextStyle(color: AppColors.textSecondary)),
                  );
                }

                // Sort by createdAt descending
                final sortedNotes = List<NoteItem>.from(notes)..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: sortedNotes.length,
                  itemBuilder: (context, index) {
                    final note = sortedNotes[index];
                    return _buildPostIt(context, note);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostIt(BuildContext context, NoteItem note) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    return GestureDetector(
      onTap: () => _showAddNoteSheet(context, note),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: note.color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  note.type == NoteType.group ? Icons.people_alt_rounded : Icons.person_rounded,
                  size: 16,
                  color: Colors.black54,
                ),
                if (note.reminderTime != null)
                  const Icon(Icons.alarm_rounded, size: 16, color: Colors.black54),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              note.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                note.content,
                overflow: TextOverflow.fade,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (note.reminderTime != null)
              Text(
                '⏰ ${dateFormat.format(note.reminderTime!)}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.black54,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
