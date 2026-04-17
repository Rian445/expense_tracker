import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_theme.dart';
import '../services/backup_service.dart';
import '../providers/theme_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/category_provider.dart';
import '../providers/earning_provider.dart';
import '../providers/analytics_provider.dart';

class BackupRestoreScreen extends ConsumerWidget {
  const BackupRestoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Secure Data Vault'),
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
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: [
                  const Icon(Icons.cloud_sync_rounded, color: Colors.white, size: 56),
                  const SizedBox(height: 16),
                  const Text(
                    'Vault Management',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Export or restore your entire financial mirror securely.',
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

            // ── Security Shield Section ─────────────────────────────────────
            _SecurityShield(isDarkMode: isDarkMode),
            const SizedBox(height: 32),

            // ── Actions ─────────────────────────────────────────────────────
            _VaultActionCard(
              title: 'Create Secure Export',
              subtitle: 'Encrypt and save your data vault.',
              icon: Icons.cloud_upload_outlined,
              color: const Color(0xFF6366F1),
              isDarkMode: isDarkMode,
              onTap: () async {
                final password = await _showPasswordDialog(context, isExport: true);
                if (password == null || password.isEmpty) return;

                try {
                  await BackupService.exportBackup(password);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vault exported successfully! 🔐')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Backup failed: $e'))
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 16),
            _VaultActionCard(
              title: 'Restore from Vault',
              subtitle: 'Import data from an encrypted .etv file.',
              icon: Icons.cloud_download_outlined,
              color: const Color(0xFF10B981),
              isDarkMode: isDarkMode,
              onTap: () async {
                // 1. Pick the file first
                final file = await BackupService.pickBackupFile();
                if (file == null) return;

                // 2. Ask for password only if file is picked
                if (context.mounted) {
                  final password = await _showPasswordDialog(context, isExport: false);
                  if (password == null || password.isEmpty) return;

                  try {
                    final success = await BackupService.importBackup(file, password);
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Data restored successfully! Refreshing...'))
                      );
                      ref.invalidate(expenseProvider);
                      ref.invalidate(categoryTotalsProvider);
                      ref.invalidate(categoryProvider);
                      ref.invalidate(earningProvider);
                      ref.invalidate(themeModeProvider);
                      ref.invalidate(analyticsTimeframeProvider);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Restore failed: $e'))
                      );
                    }
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showPasswordDialog(BuildContext context, {required bool isExport}) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(
                isExport ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
                color: const Color(0xFF6366F1),
              ),
              const SizedBox(width: 12),
              Text(
                isExport ? 'Secure My Vault' : 'Unlock Vault',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isExport
                    ? 'Set a password to encrypt this backup. You will need this to restore it later.'
                    : 'Enter the password you used when creating this backup.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDarkMode ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                obscureText: true,
                autofocus: true,
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: 'Enter Password',
                  hintStyle: const TextStyle(fontSize: 14),
                  filled: true,
                  fillColor: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.key_rounded, size: 20),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: isDarkMode ? Colors.white38 : Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(isExport ? 'Create Secure Backup' : 'Restore Data'),
            ),
          ],
        );
      },
    );
  }
}

class _SecurityShield extends StatelessWidget {
  final bool isDarkMode;
  const _SecurityShield({required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_rounded, color: Color(0xFF6366F1), size: 28),
              const SizedBox(width: 12),
              Text(
                'Military-Grade Protection',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDarkMode ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SecurityFeature(
            icon: Icons.enhanced_encryption_rounded,
            title: 'AES-256 Vault Encryption',
            desc: 'Every backup is transformed into a high-security encrypted vault using the Advanced Encryption Standard.',
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 12),
          _SecurityFeature(
            icon: Icons.vpn_key_rounded,
            title: 'User-Locked Security',
            desc: 'Your data is locked by your specific password. Not even we can open your backup files.',
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 12),
          _SecurityFeature(
            icon: Icons.cloud_off_rounded,
            title: 'Zero Cloud Exposure',
            desc: 'We never store your backups on our servers. You have 100% control over your data files.',
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 12),
          _SecurityFeature(
            icon: Icons.history_rounded,
            title: 'Full Mirroring',
            desc: 'Backs up everything: expenses, earnings, loans, categories, and theme settings.',
            isDarkMode: isDarkMode,
          ),
        ],
      ),
    );
  }
}

class _SecurityFeature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final bool isDarkMode;

  const _SecurityFeature({
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
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF6366F1)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDarkMode ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 12,
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

class _VaultActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isDarkMode;
  final VoidCallback onTap;

  const _VaultActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDarkMode ? Colors.white12 : Colors.grey.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDarkMode ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white38 : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: isDarkMode ? Colors.white24 : Colors.grey),
          ],
        ),
      ),
    );
  }
}
