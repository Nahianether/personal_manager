import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../providers/account_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/loan_provider.dart';
import '../providers/liability_provider.dart';
import '../providers/category_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/sync_provider.dart';
import '../services/database_service.dart';
import '../services/excel_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final authState = ref.watch(authProvider);
    
    // Listen to auth state changes and navigate to login when signed out
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous?.isAuthenticated == true && next.isAuthenticated == false) {
        // User has been signed out, pop all routes and let main app handle navigation
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  if (authState.user != null) ...[
                    _buildInfoRow(
                      context,
                      Icons.person,
                      'Name',
                      authState.user!.name,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context,
                      Icons.email,
                      'Email',
                      authState.user!.email,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _buildActionRow(
                    context,
                    Icons.logout,
                    'Sign Out',
                    'Sign out of your account',
                    () => _showLogoutDialog(context, ref),
                    isDestructive: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appearance',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => _showThemeSelectionDialog(context, ref),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              themeState.currentTheme.icon,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Theme',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(
                                  'Current: ${themeState.currentTheme.label}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    context,
                    Icons.info_outline_rounded,
                    'Version',
                    '1.0.0',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    context,
                    Icons.developer_mode_rounded,
                    'Developer',
                    'Personal Manager Team',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    context,
                    Icons.description_outlined,
                    'License',
                    'MIT License',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data Management',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildActionRow(
                    context,
                    Icons.file_download_outlined,
                    'Export Data',
                    'Export all data to Excel file',
                    () => _exportData(context, ref),
                  ),
                  const SizedBox(height: 12),
                  _buildActionRow(
                    context,
                    Icons.file_upload_outlined,
                    'Import Data',
                    'Import data from Excel file',
                    () => _importData(context, ref),
                  ),
                  const SizedBox(height: 12),
                  _buildActionRow(
                    context,
                    Icons.delete_forever_outlined,
                    'Delete All Data',
                    'Permanently delete all your data',
                    () => _showDeleteAllDataDialog(context, ref),
                    isDestructive: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Support',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildActionRow(
                    context,
                    Icons.help_outline_rounded,
                    'Help & FAQ',
                    'Get help and find answers',
                    () {},
                  ),
                  const SizedBox(height: 12),
                  _buildActionRow(
                    context,
                    Icons.feedback_outlined,
                    'Send Feedback',
                    'Share your thoughts with us',
                    () {},
                  ),
                  const SizedBox(height: 12),
                  _buildActionRow(
                    context,
                    Icons.star_outline_rounded,
                    'Rate App',
                    'Rate us on the app store',
                    () {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildActionRow(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDestructive 
                    ? Theme.of(context).colorScheme.errorContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isDestructive
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: isDestructive ? Theme.of(context).colorScheme.error : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDestructive 
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeSelectionDialog(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.read(themeProvider).currentTheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppTheme.values.map((theme) {
            return RadioListTile<AppTheme>(
              value: theme,
              groupValue: currentTheme,
              onChanged: (AppTheme? value) {
                if (value != null) {
                  ref.read(themeProvider.notifier).setTheme(value);
                  Navigator.pop(context);
                }
              },
              title: Text(theme.label),
              subtitle: Text(_getThemeDescription(theme)),
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getThemeColor(theme).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  theme.icon,
                  color: _getThemeColor(theme),
                  size: 20,
                ),
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  String _getThemeDescription(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return 'Always use light theme';
      case AppTheme.dark:
        return 'Always use dark theme';
      case AppTheme.auto:
        return 'Follow system setting';
    }
  }

  Color _getThemeColor(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return const Color(0xFF1A73E8); // Light theme primary color
      case AppTheme.dark:
        return const Color(0xFF4285F4); // Dark theme primary color
      case AppTheme.auto:
        // For auto, use a neutral color that represents system sync
        return const Color(0xFF9C27B0); // Purple color for auto mode
    }
  }

  void _showDeleteAllDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Data'),
        content: const Text(
          'Are you sure you want to delete ALL your data?\n\n'
          'This will permanently remove:\n'
          '• All accounts\n'
          '• All transactions\n'
          '• All loans\n'
          '• All liabilities\n'
          '• All custom categories\n\n'
          'This action cannot be undone!'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAllData(context, ref);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAllData(BuildContext context, WidgetRef ref) async {
    if (!context.mounted) return;
    
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Deleting all data...'),
            ],
          ),
        ),
      );

      // Delete all data from database for current user only
      await DatabaseService().clearAllUserData();

      // Refresh all providers
      ref.invalidate(accountProvider);
      ref.invalidate(transactionProvider);
      ref.invalidate(loanProvider);
      ref.invalidate(liabilityProvider);
      ref.invalidate(categoryProvider);

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting data: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    if (!context.mounted) return;
    
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Exporting data...'),
            ],
          ),
        ),
      );

      final success = await ExcelService().exportToExcel();

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data exported successfully to Downloads folder'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to export data'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _importData(BuildContext context, WidgetRef ref) async {
    if (!context.mounted) return;
    
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import Data'),
          content: const Text(
            'Importing data will replace ALL existing data.\n\n'
            'Make sure you have a backup before proceeding.\n\n'
            'Do you want to continue?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Import'),
            ),
          ],
        ),
      );

      if (confirmed != true || !context.mounted) return;

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Importing data...'),
            ],
          ),
        ),
      );

      final success = await ExcelService().importFromExcel();

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        if (success) {
          // Refresh all providers
          ref.invalidate(accountProvider);
          ref.invalidate(transactionProvider);
          ref.invalidate(loanProvider);
          ref.invalidate(liabilityProvider);
          ref.invalidate(categoryProvider);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data imported successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to import data. Please check file format.'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performSignout(ref);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Future<void> _performSignout(WidgetRef ref) async {
    try {
      print('🔄 Starting complete signout process...');
      
      // Sign out from auth provider (this will clear all user data)
      await ref.read(authProvider.notifier).signout();
      
      // Invalidate all other providers to clear their state
      ref.invalidate(accountProvider);
      ref.invalidate(transactionProvider);
      ref.invalidate(loanProvider);
      ref.invalidate(liabilityProvider);
      ref.invalidate(categoryProvider);
      ref.invalidate(syncProvider);
      
      print('✅ Complete signout process finished');
    } catch (e) {
      print('❌ Error during signout: $e');
      // Even if there's an error, the auth state should be cleared
      // and the user will be redirected to login screen
    }
  }
}