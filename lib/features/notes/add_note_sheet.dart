import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../main.dart'; // AppColors
import '../../models/note_models.dart';
import 'providers/note_provider.dart';
import '../../services/notification_service.dart';

class AddNoteSheet extends ConsumerStatefulWidget {
  final NoteItem? noteToEdit;
  const AddNoteSheet({Key? key, this.noteToEdit}) : super(key: key);

  @override
  ConsumerState<AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends ConsumerState<AddNoteSheet> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  NoteType _selectedType = NoteType.personal;
  Color _selectedColor = const Color(0xFFFFF176); // Amarillo Post-it
  DateTime? _reminderTime;
  bool _isSaving = false;

  final List<Color> _postItColors = [
    const Color(0xFFFFF176), // Amarillo
    const Color(0xFFFFB74D), // Naranja
    const Color(0xFF81C784), // Verde
    const Color(0xFF4FC3F7), // Azul
    const Color(0xFFBA68C8), // Morado
    const Color(0xFFE57373), // Rojo claro
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.noteToEdit?.title ?? '');
    _contentController = TextEditingController(text: widget.noteToEdit?.content ?? '');
    if (widget.noteToEdit != null) {
      _selectedType = widget.noteToEdit!.type;
      _selectedColor = widget.noteToEdit!.color;
      _reminderTime = widget.noteToEdit!.reminderTime;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickReminderTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _reminderTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_reminderTime ?? DateTime.now()),
    );
    if (time == null) return;

    setState(() {
      _reminderTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _saveNote() async {
    if (_titleController.text.trim().isEmpty) return;

    setState(() => _isSaving = true);
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    final note = NoteItem(
      id: widget.noteToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      authorId: widget.noteToEdit?.authorId ?? userId,
      type: _selectedType,
      reminderTime: _reminderTime,
      color: _selectedColor,
      createdAt: widget.noteToEdit?.createdAt ?? DateTime.now(),
    );

    await ref.read(noteServiceProvider).saveNote(note);

    if (_reminderTime != null && _reminderTime!.isAfter(DateTime.now())) {
      // Programar alarma local (solo en este dispositivo)
      await NotificationService().scheduleNotification(
        id: note.id.hashCode,
        title: 'Recordatorio: ${note.title}',
        body: note.content.isNotEmpty ? note.content : 'Revisa tu nota en la app.',
        scheduledDate: _reminderTime!,
      );
    } else if (_reminderTime == null && widget.noteToEdit?.reminderTime != null) {
      // Cancelar alarma si la quitaron
      await NotificationService().cancelNotification(note.id.hashCode);
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _deleteNote() async {
    if (widget.noteToEdit != null) {
      setState(() => _isSaving = true);
      await ref.read(noteServiceProvider).deleteNote(widget.noteToEdit!.id);
      await NotificationService().cancelNotification(widget.noteToEdit!.id.hashCode);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.noteToEdit == null ? 'Nueva Nota ✨' : 'Editar Nota ✍️',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                if (widget.noteToEdit != null)
                  IconButton(
                    onPressed: _deleteNote,
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.coral),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Color Picker
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _postItColors.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final c = _postItColors[index];
                  final isSelected = c.value == _selectedColor.value;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = c),
                    child: Container(
                      width: 40,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.black54 : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: isSelected ? const Icon(Icons.check, size: 20, color: Colors.black54) : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Tipo de Nota
            Row(
              children: [
                _buildTypeChip('Personal', NoteType.personal, Icons.person_rounded),
                const SizedBox(width: 12),
                _buildTypeChip('Grupal', NoteType.group, Icons.people_alt_rounded),
              ],
            ),
            const SizedBox(height: 20),

            // Recordatorio
            GestureDetector(
              onTap: _pickReminderTime,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.lavenderLight),
                ),
                child: Row(
                  children: [
                    Icon(Icons.alarm_add_rounded, color: _reminderTime != null ? AppColors.pink : AppColors.textSecondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _reminderTime != null
                            ? 'Recordatorio: ${DateFormat('dd MMM yyyy, HH:mm').format(_reminderTime!)}'
                            : 'Agregar recordatorio local',
                        style: TextStyle(
                          color: _reminderTime != null ? AppColors.textPrimary : AppColors.textSecondary,
                          fontWeight: _reminderTime != null ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (_reminderTime != null)
                      GestureDetector(
                        onTap: () => setState(() => _reminderTime = null),
                        child: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Título
            TextField(
              controller: _titleController,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(
                hintText: 'Título de la nota',
                border: InputBorder.none,
              ),
            ),
            
            // Contenido
            TextField(
              controller: _contentController,
              style: const TextStyle(fontSize: 15, height: 1.5),
              maxLines: 8,
              minLines: 3,
              decoration: const InputDecoration(
                hintText: 'Escribe tu nota aquí...',
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.pink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: _isSaving ? null : _saveNote,
                child: _isSaving
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Guardar Nota ✨', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(String label, NoteType type, IconData icon) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.pink : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.pink : AppColors.lavenderLight),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
