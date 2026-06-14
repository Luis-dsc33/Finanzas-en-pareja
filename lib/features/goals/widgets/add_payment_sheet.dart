import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../main.dart';
import '../../../models/goal_models.dart';
import '../providers/goal_provider.dart';

class AddPaymentSheet extends ConsumerStatefulWidget {
  final SavingsGoal? goal;
  final DebtItem? debt;

  const AddPaymentSheet({Key? key, this.goal, this.debt}) 
      : assert(goal != null || debt != null), super(key: key);

  @override
  ConsumerState<AddPaymentSheet> createState() => _AddPaymentSheetState();
}

class _AddPaymentSheetState extends ConsumerState<AddPaymentSheet> {
  final _amountController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _savePayment() async {
    if (_amountController.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    
    try {
      final amount = double.parse(_amountController.text);
      final service = ref.read(goalServiceProvider);
      
      if (widget.goal != null) {
        final updatedGoal = widget.goal!.copyWith(
          currentAmount: widget.goal!.currentAmount + amount,
        );
        await service.saveSavingsGoal(updatedGoal);
      } else if (widget.debt != null) {
        final updatedDebt = widget.debt!.copyWith(
          balance: widget.debt!.balance - amount, // Restar del balance
        );
        await service.saveDebt(updatedDebt);
      }
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGoal = widget.goal != null;
    final colorHex = isGoal ? widget.goal!.colorHex : widget.debt!.colorHex;
    final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    final title = isGoal ? 'Abonar a Meta' : 'Pagar Deuda';
    final itemName = isGoal ? widget.goal!.title : widget.debt!.title;

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
              '$title 💸',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              itemName,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: '\$0.00',
                prefixText: '\$ ',
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _savePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
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
                        'Registrar',
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
