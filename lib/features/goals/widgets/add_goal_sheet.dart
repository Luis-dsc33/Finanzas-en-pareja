import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../main.dart'; // Para AppColors
import '../../../models/goal_models.dart';
import '../providers/goal_provider.dart';

class AddGoalSheet extends ConsumerStatefulWidget {
  final SavingsGoal? goalToEdit;

  const AddGoalSheet({Key? key, this.goalToEdit}) : super(key: key);

  @override
  ConsumerState<AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends ConsumerState<AddGoalSheet> {
  final _titleController = TextEditingController();
  final _targetController = TextEditingController();
  final _monthlyTargetController = TextEditingController();
  final _emojiController = TextEditingController(text: '🎯');
  
  String _selectedColor = '#B8A9E8'; // Default lavender
  final List<String> _colors = ['#B8A9E8', '#F2B5D4', '#A8E6CF', '#FFD3B6', '#A8D8EA', '#FFF5BA', '#FFADAD'];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.goalToEdit != null) {
      _titleController.text = widget.goalToEdit!.title;
      _targetController.text = widget.goalToEdit!.targetAmount.toStringAsFixed(0);
      _monthlyTargetController.text = widget.goalToEdit!.monthlyTarget.toStringAsFixed(0);
      _emojiController.text = widget.goalToEdit!.emoji;
      _selectedColor = widget.goalToEdit!.colorHex;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _monthlyTargetController.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  void _saveGoal() async {
    if (_titleController.text.isEmpty || _targetController.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    
    try {
      final target = double.parse(_targetController.text);
      final monthly = double.tryParse(_monthlyTargetController.text) ?? 0;
      
      final goal = SavingsGoal(
        id: widget.goalToEdit?.id ?? const Uuid().v4(),
        title: _titleController.text,
        emoji: _emojiController.text,
        currentAmount: widget.goalToEdit?.currentAmount ?? 0,
        targetAmount: target,
        monthlyTarget: monthly,
        colorHex: _selectedColor,
      );

      await ref.read(goalServiceProvider).saveSavingsGoal(goal);
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      // Ignorar errores de parseo
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.textLight.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.goalToEdit == null ? 'Nueva Meta 🎯' : 'Editar Meta 🎯',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                SizedBox(
                  width: 60,
                  child: TextField(
                    controller: _emojiController,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.cardBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'Título (ej. Casa Querétaro)',
                      filled: true,
                      fillColor: AppColors.cardBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _targetController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Monto objetivo (\$)',
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _monthlyTargetController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Aporte mensual ideal (\$)',
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Color',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _colors.map((hex) {
                  final color = Color(int.parse(hex.replaceFirst('#', '0xFF')));
                  final isSelected = _selectedColor == hex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = hex),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: AppColors.textPrimary, width: 2) : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveGoal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lavender,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Guardar Meta',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
