import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_theme.dart';
import '../core/services/sms_service.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';

class SmsSettingsScreen extends ConsumerWidget {
  const SmsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;
    final isEnabled = ref.watch(smsAutoTrackingProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('SMS Auto Tracking'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: isDarkMode ? Colors.white : AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header illustration ─────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: [
                  const Icon(Icons.sms_rounded, color: Colors.white, size: 56),
                  const SizedBox(height: 16),
                  const Text(
                    'SMS Auto Expense',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Automatically create expense entries from bank SMS messages.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Privacy & Security Shield ──────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 28),
                      const SizedBox(width: 12),
                      Text(
                        'Privacy First. Always.',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDarkMode ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _PrivacyFeature(
                    icon: Icons.wifi_off_rounded,
                    title: 'Offline Data Isolation',
                    desc: 'Engineered for absolute privacy. Internet access is physically disabled, so no data can ever leave your device.',
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 12),
                  _PrivacyFeature(
                    icon: Icons.storage_rounded,
                    title: 'On-Device Analysis',
                    desc: 'The "Brain" of the app lives inside your phone. All SMS parsing and expense matching happen locally.',
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 12),
                  _PrivacyFeature(
                    icon: Icons.visibility_off_rounded,
                    title: 'Financial-Only Focus',
                    desc: 'We only scan for banking keywords. Your personal conversations, private chats, and OTPs remain completely invisible to the app.',
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 12),
                  _PrivacyFeature(
                    icon: Icons.security_rounded,
                    title: 'Breach-Proof Isolation',
                    desc: 'No Internet permission means no data can be breached. Your information is physically trapped inside your phone, making it immune to online leaks.',
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 12),
                  _PrivacyFeature(
                    icon: Icons.enhanced_encryption_rounded,
                    title: 'Hardware-Backed Encryption',
                    desc: 'Your data is locked with AES-256 encryption. The keys are stored in your device\'s secure hardware vault, making it invisible to other apps.',
                    isDarkMode: isDarkMode,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Toggle ──────────────────────────────────────────────────────
            _SettingsCard(
              isDarkMode: isDarkMode,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (isEnabled ? AppColors.primary : Colors.grey)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: isEnabled ? AppColors.primary : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enable SMS Auto Tracking',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDarkMode ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isEnabled
                              ? 'Listening for bank transactions...'
                              : 'Tap to enable. Requires SMS permission.',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                isDarkMode ? Colors.white38 : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: isEnabled,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.primary,
                    onChanged: (val) async {
                      if (val) {
                        // Request permissions & start listener
                        final granted = await SmsService.enable(ref);
                        if (!granted && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('SMS permission denied. Please grant it in Settings.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }
                      } else {
                        SmsService.disable();
                      }
                      ref.read(smsAutoTrackingProvider.notifier).set(val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── How it works ────────────────────────────────────────────────
            Text(
              'How it works',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isDarkMode ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ..._steps(isDarkMode),
            const SizedBox(height: 24),

            // ── Supported banks ─────────────────────────────────────────────
            Text(
              'Supported Banks & Services',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isDarkMode ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _SettingsCard(
              isDarkMode: isDarkMode,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'UCB', 'DBBL', 'BRAC', 'City Bank', 'EBL', 'HSBC',
                  'Islami Bank', 'AB Bank', 'MTB', 'Prime Bank', 'SEBL',
                  'NexusPay', 'Nagad', 'bKash',
                ].map((bank) => Chip(
                  label: Text(bank, style: const TextStyle(fontSize: 12)),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
                  labelStyle: TextStyle(
                    color: isDarkMode ? Colors.white70 : AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: 24),


          ],
        ),
      ),
    );
  }

  List<Widget> _steps(bool isDarkMode) {
    final steps = [
      ('📨', 'Bank sends you an SMS', 'Any debit/charge notification'),
      ('🔍', 'App detects the transaction', 'Expense keywords trigger parsing'),
      ('🏷️', 'Category auto-assigned', 'Based on merchant name (e.g. KFC → Food)'),
      ('💾', 'Expense created instantly', 'Tagged with Auto (SMS) badge'),
    ];
    return steps.map((s) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(child: Text(s.$1, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.$2, style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isDarkMode ? Colors.white : AppColors.textPrimary,
                )),
                Text(s.$3, style: TextStyle(
                  fontSize: 11,
                  color: isDarkMode ? Colors.white38 : AppColors.textSecondary,
                )),
              ],
            ),
          ),
        ],
      ),
    )).toList();
  }
}

class _SettingsCard extends StatelessWidget {
  final bool isDarkMode;
  final Widget child;
  const _SettingsCard({required this.isDarkMode, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.withValues(alpha: 0.12),
        ),
      ),
      child: child,
    );
  }
}

class _PrivacyFeature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final bool isDarkMode;

  const _PrivacyFeature({
    required this.icon,
    required this.title,
    required this.desc,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF10B981).withValues(alpha: 0.7), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isDarkMode ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 11,
                  color: isDarkMode ? Colors.white38 : AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
