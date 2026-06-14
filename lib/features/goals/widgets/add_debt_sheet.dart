import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../main.dart'; // Para AppColors
import '../../../models/goal_models.dart';
import '../providers/goal_provider.dart';

class AddDebtSheet extends ConsumerStatefulWidget {
  final DebtItem? debtToEdit;

  const AddDebtSheet({Key? key, this.debtToEdit}) : super(key: key);

  @override
  ConsumerState<AddDebtSheet> createState() => _AddDebtSheetState();
}

class _AddDebtSheetState extends ConsumerState<AddDebtSheet> {
  final _titleController = TextEditingController();
  final _balanceController = TextEditingController();
  final _monthlyPaymentController = TextEditingController();
  
  String _selectedColor = '#F2B5D4'; // Default pink
  final List<String> _colors = ['#B8A9E8', '#F2B5D4', '#A8E6CF', '#FFD3B6', '#A8D8EA', '#FFF5BA', '#FFADAD'];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.debtToEdit != null) {
      _titleController.text = widget.debtToEdit!.title;
      _balanceController.text = widget.debtToEdit!.balance.toStringAsFixed(0);
      _monthlyPaymentController.text = widget.debtToEdit!.monthlyPayment.toStringAsFixed(0);
      _selectedColor = widget.debtToEdit!.colorHex;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _balanceController.dispose();
    _monthlyPaymentController.dispose();
    super.dispose();
  }

  void _saveDebt() async {
    if (_titleController.text.isEmpty || _balanceController.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    
    try {
      final balance = double.parse(_balanceController.text);
      final monthly = double.tryParse(_monthlyPaymentController.text) ?? 0;
      
      final debt = DebtItem(
        id: widget.debtToEdit?.id ?? const Uuid().v4(),
        title: _titleController.text,
        balance: balance,
        monthlyPayment: monthly,
        colorHex: _selectedColor,
      );

      await ref.read(goalServiceProvider).saveDebt(debt);
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
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
              widget.debtToEdit == null ? 'Nueva Deuda 💳' : 'Editar Deuda 💳',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Nombre de la deuda (ej. Tarjeta de Crédito)',
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
              controller: _balanceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Saldo actual (\$)',
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
              controller: _monthlyPaymentController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Pago mensual sugerido (\$)',
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
                onPressed: _isLoading ? null : _saveDebt,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.pink,
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
                        'Guardar Deuda',
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
