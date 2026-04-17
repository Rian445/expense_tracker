import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../providers/settings_provider.dart';
import '../core/constants/app_theme.dart';
import '../core/services/sms_service.dart';
import 'dashboard_screen.dart';
import 'earning_screen.dart';
import 'loan_screen.dart';
import 'placeholder_screens.dart';

class _BottomNavIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) => state = index;
}

final _bottomNavIndexProvider = NotifierProvider<_BottomNavIndexNotifier, int>(() {
  return _BottomNavIndexNotifier();
});

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    // Auto-start SMS service if user had previously enabled it
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isEnabled = ref.read(smsAutoTrackingProvider);
      if (isEnabled) {
        SmsService.enable(ref);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(_bottomNavIndexProvider);
    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;


    final pages = const [
      DashboardScreen(),
      EarningScreen(),
      LoanScreen(),
      SummaryScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.4 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
          border: Border(
            top: BorderSide(
              color: isDarkMode ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.1),
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.money_off_rounded,
                  activeIcon: Icons.money_off_rounded,
                  label: 'Spending',
                  isSelected: currentIndex == 0,
                  isDarkMode: isDarkMode,
                  onTap: () => ref.read(_bottomNavIndexProvider.notifier).setIndex(0),
                ),
                _NavItem(
                  icon: Icons.trending_up_outlined,
                  activeIcon: Icons.trending_up_rounded,
                  label: 'Earning',
                  isSelected: currentIndex == 1,
                  isDarkMode: isDarkMode,
                  onTap: () => ref.read(_bottomNavIndexProvider.notifier).setIndex(1),
                ),
                _NavItem(
                  icon: Icons.account_balance_outlined,
                  activeIcon: Icons.account_balance_rounded,
                  label: 'Loan',
                  isSelected: currentIndex == 2,
                  isDarkMode: isDarkMode,
                  onTap: () => ref.read(_bottomNavIndexProvider.notifier).setIndex(2),
                ),
                _NavItem(
                  icon: Icons.insights_outlined,
                  activeIcon: Icons.insights_rounded,
                  label: 'Summary',
                  isSelected: currentIndex == 3,
                  isDarkMode: isDarkMode,
                  onTap: () => ref.read(_bottomNavIndexProvider.notifier).setIndex(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final bool isDarkMode;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected
                  ? AppColors.primary
                  : (isDarkMode ? Colors.white38 : AppColors.textSecondary),
              size: 22,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: isSelected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
