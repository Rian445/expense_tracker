import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../providers/category_provider.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _subCategoryController = TextEditingController();
  String _paymentMethod = 'Cash';

  String _normalize(String input) {
    if (input.isEmpty) return '';
    return input[0].toUpperCase() + input.substring(1).toLowerCase();
  }

  void _saveExpense() {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final category = _normalize(_categoryController.text.trim());
    final subCategory = _normalize(_subCategoryController.text.trim());

    if (category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category is required')),
      );
      return;
    }

    final String id = DateTime.now().toIso8601String();
    final expense = Expense(
      id: id,
      category: category,
      subCategory: subCategory.isEmpty ? null : subCategory,
      amount: amount,
      paymentMethod: _paymentMethod,
      date: DateTime.now(),
    );

    ref.read(categoryProvider.notifier).addCategoryOrSubcategory(category, subCategory.isEmpty ? null : subCategory);
    ref.read(expenseProvider.notifier).addExpense(expense);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryProvider);
    final selectedCategory = _normalize(_categoryController.text.trim());
    final subCategories = categories[selectedCategory] ?? <String>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(labelText: 'Category'),
              onChanged: (val) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: categories.keys.map((cat) {
                return ActionChip(
                  label: Text(cat),
                  onPressed: () {
                    setState(() {
                      _categoryController.text = cat;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _subCategoryController,
              decoration: const InputDecoration(labelText: 'Subcategory'),
            ),
            const SizedBox(height: 8),
            if (subCategories.isNotEmpty)
              Wrap(
                spacing: 8,
                children: subCategories.map((subCat) {
                  return ActionChip(
                    label: Text(subCat),
                    onPressed: () {
                      setState(() {
                        _subCategoryController.text = subCat;
                      });
                    },
                  );
                }).toList(),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _paymentMethod,
              items: ['Cash', 'Bank', 'Card', 'Bkash', 'Nagad']
                  .map((method) => DropdownMenuItem(
                        value: method,
                        child: Text(method),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _paymentMethod = val;
                  });
                }
              },
              decoration: const InputDecoration(labelText: 'Payment Method'),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveExpense,
              child: const Text('Save Expense'),
            ),
          ],
        ),
      ),
    );
  }
}
