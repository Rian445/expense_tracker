import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../providers/category_provider.dart';
import '../core/constants/app_theme.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _subCategoryController = TextEditingController();
  String _selectedPaymentMethod = 'Cash';
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
    _subCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Add Expense'),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How much?', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                prefixText: '\$ ',
                border: InputBorder.none,
                hintText: '0.00',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 40),
            _BuildFormSection(
              label: 'Category',
              child: _ModernDropdownField(
                controller: _categoryController,
                hint: 'Select or type category',
                suggestions: categories.keys.toList(),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 24),
            _BuildFormSection(
              label: 'Subcategory',
              child: _ModernDropdownField(
                controller: _subCategoryController,
                hint: 'Specific detail...',
                suggestions: _categoryController.text.isNotEmpty 
                    ? categories[_categoryController.text] ?? [] 
                    : [],
              ),
            ),
            const SizedBox(height: 24),
            _BuildFormSection(
              label: 'Payment Method',
              child: Row(
                children: ['Cash', 'Card', 'Other'].map((m) {
                  final isSelected = _selectedPaymentMethod == m;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(m),
                      selected: isSelected,
                      onSelected: (v) => setState(() => _selectedPaymentMethod = m),
                      selectedColor: AppColors.primary.withValues(alpha: 0.1),
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            _BuildFormSection(
              label: 'Date',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) setState(() => _selectedDate = date);
                },
                leading: const Icon(Icons.calendar_today_outlined, color: AppColors.primary),
                title: Text(DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate)),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _saveExpense,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: const Text('Save Expense', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveExpense() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0 || _categoryController.text.isEmpty) return;

    final expense = Expense(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      category: _categoryController.text,
      subCategory: _subCategoryController.text.isEmpty ? null : _subCategoryController.text,
      amount: amount,
      paymentMethod: _selectedPaymentMethod,
      date: _selectedDate,
    );

    ref.read(expenseProvider.notifier).addExpense(expense);
    ref.read(categoryProvider.notifier).addCategoryOrSubcategory(
      expense.category, 
      expense.subCategory
    );
    
    Navigator.pop(context);
  }
}

class _BuildFormSection extends StatelessWidget {
  final String label;
  final Widget child;
  const _BuildFormSection({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _ModernDropdownField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final List<String> suggestions;
  final ValueChanged<String>? onChanged;

  const _ModernDropdownField({
    required this.controller,
    required this.hint,
    required this.suggestions,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Autocomplete<String>(
        optionsBuilder: (textEditingValue) {
          if (textEditingValue.text.isEmpty) return suggestions;
          return suggestions.where((s) => s.toLowerCase().contains(textEditingValue.text.toLowerCase()));
        },
        onSelected: (selection) {
          controller.text = selection;
          if (onChanged != null) onChanged!(selection);
        },
        fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
          if (controller.text.isNotEmpty && textController.text.isEmpty) {
            textController.text = controller.text;
          }
          return TextField(
            controller: textController,
            focusNode: focusNode,
            onChanged: (v) {
              controller.text = v;
              if (onChanged != null) onChanged!(v);
            },
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              hintStyle: const TextStyle(color: Colors.grey),
            ),
          );
        },
      ),
    );
  }
}
