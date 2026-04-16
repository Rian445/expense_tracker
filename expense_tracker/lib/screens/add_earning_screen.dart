import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/earning.dart';
import '../providers/earning_provider.dart';
import '../core/constants/app_theme.dart';
import '../providers/theme_provider.dart';
import '../providers/settings_provider.dart';

class AddEarningScreen extends ConsumerStatefulWidget {
  const AddEarningScreen({super.key});

  @override
  ConsumerState<AddEarningScreen> createState() => _AddEarningScreenState();
}

class _AddEarningScreenState extends ConsumerState<AddEarningScreen> {
  final _amountController = TextEditingController();
  final _sourceController = TextEditingController();
  String _selectedReceiveMethod = 'Cash';
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final earnings = ref.watch(earningProvider);
    final Set<String> suggestSources = earnings.map((e) => e.incomeSource).toSet();
    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;
    final currency = ref.watch(currencyProvider);
    final theme = Theme.of(context);

    // Earning specific theme color
    final primaryColor = Colors.green.shade600;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Add Earning'),
        leading: IconButton(
          icon: Icon(Icons.close, color: isDarkMode ? Colors.white : AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount', style: TextStyle(color: isDarkMode ? Colors.white70 : AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                fontSize: 48, 
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                prefixText: '${currency.symbol} ',
                prefixStyle: TextStyle(
                  fontSize: 48, 
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : AppColors.textPrimary,
                ),
                border: InputBorder.none,
                hintText: '0.00',
                hintStyle: TextStyle(color: isDarkMode ? Colors.white24 : Colors.grey.withValues(alpha: 0.3)),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 40),
            _BuildFormSection(
              label: 'Income source',
              child: _ModernDropdownField(
                controller: _sourceController,
                hint: 'Salary, Freelance, etc.',
                suggestions: suggestSources.toList(),
                onChanged: (_) => setState(() {}),
                isDarkMode: isDarkMode,
              ),
            ),
            const SizedBox(height: 24),
            _BuildFormSection(
              label: 'Receive Method',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Bank', 'Cash', 'Bkash', 'Rocket', 'Nogod'].map((m) {
                  final isSelected = _selectedReceiveMethod == m;
                  return ChoiceChip(
                    label: Text(m),
                    selected: isSelected,
                    onSelected: (v) => setState(() => _selectedReceiveMethod = m),
                    selectedColor: primaryColor.withValues(alpha: 0.2),
                    backgroundColor: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05),
                    labelStyle: TextStyle(
                      color: isSelected 
                          ? primaryColor 
                          : (isDarkMode ? Colors.white60 : AppColors.textSecondary),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? primaryColor : Colors.grey.withValues(alpha: 0.1),
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
                leading: Icon(Icons.calendar_today_outlined, color: primaryColor),
                title: Text(
                  DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate),
                  style: TextStyle(color: isDarkMode ? Colors.white : AppColors.textPrimary),
                ),
                trailing: Icon(Icons.chevron_right, color: isDarkMode ? Colors.white24 : Colors.grey),
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _saveEarning,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: const Text('Save Earning', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveEarning() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0 || _sourceController.text.isEmpty) return;

    final earning = Earning(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      incomeSource: _sourceController.text,
      amount: amount,
      receiveMethod: _selectedReceiveMethod,
      date: _selectedDate,
    );

    ref.read(earningProvider.notifier).addEarning(earning);
    Navigator.pop(context);
  }
}

class _BuildFormSection extends StatelessWidget {
  final String label;
  final Widget child;
  const _BuildFormSection({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(
          fontWeight: FontWeight.bold, 
          fontSize: 16,
          color: isDarkMode ? Colors.white : AppColors.textPrimary,
        )),
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
  final bool isDarkMode;

  const _ModernDropdownField({
    required this.controller,
    required this.hint,
    required this.suggestions,
    this.onChanged,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : AppColors.background,
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
            style: TextStyle(color: isDarkMode ? Colors.white : AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              hintStyle: TextStyle(color: isDarkMode ? Colors.white24 : Colors.grey),
            ),
          );
        },
      ),
    );
  }
}
