import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sync_provider.dart';
import '../services/sync_service.dart';
import '../services/backend_test_service.dart';
import '../services/simple_connectivity_test.dart';

class SyncStatusWidget extends ConsumerWidget {
  const SyncStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);
    
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: syncState.isConnected 
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              syncState.isConnected 
                  ? Colors.green.withValues(alpha: 0.05)
                  : Colors.red.withValues(alpha: 0.05),
              Theme.of(context).colorScheme.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
          children: [
            // Header Section
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: syncState.isConnected ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    syncState.isConnected ? Icons.cloud_done : Icons.cloud_off,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        syncState.isConnected ? 'Connected' : 'Offline',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: syncState.isConnected ? Colors.green : Colors.red,
                        ),
                      ),
                      Text(
                        _getSyncStatusText(syncState),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (syncState.isSyncing)
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
            
            // Status Details
            if (syncState.pendingItemsCount > 0 || syncState.errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    if (syncState.pendingItemsCount > 0)
                      _buildInfoChip(
                        context,
                        Icons.upload_outlined,
                        '${syncState.pendingItemsCount} items pending',
                        Colors.orange,
                      ),
                    if (syncState.errorMessage != null) ...[
                      if (syncState.pendingItemsCount > 0) const SizedBox(height: 8),
                      _buildInfoChip(
                        context,
                        Icons.error_outline,
                        syncState.errorMessage!,
                        Colors.red,
                      ),
                    ],
                  ],
                ),
              ),
            ],
            
            // Action Buttons
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: syncState.isSyncing || !syncState.isConnected
                        ? null
                        : () => ref.read(syncProvider.notifier).syncNow(),
                    icon: const Icon(Icons.sync_rounded, size: 18),
                    label: const Text('Sync Now'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => ref.read(syncProvider.notifier).refreshPendingCount(),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Refresh'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
          ),
        ),
      ),
    );
  }

  String _getSyncStatusText(SyncState syncState) {
    if (!syncState.isConnected) return 'No internet connection';
    
    switch (syncState.syncStatus) {
      case SyncStatus.pending:
        return 'Ready to sync';
      case SyncStatus.syncing:
        return 'Syncing data...';
      case SyncStatus.synced:
        return 'All data synchronized';
      case SyncStatus.failed:
        return 'Sync failed - please retry';
    }
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSyncStatusRow(BuildContext context, SyncState syncState) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (syncState.syncStatus) {
      case SyncStatus.pending:
        statusColor = Colors.orange;
        statusText = 'Pending sync';
        statusIcon = Icons.schedule;
        break;
      case SyncStatus.syncing:
        statusColor = Colors.blue;
        statusText = 'Syncing...';
        statusIcon = Icons.sync;
        break;
      case SyncStatus.synced:
        statusColor = Colors.green;
        statusText = 'All data synced';
        statusIcon = Icons.check_circle;
        break;
      case SyncStatus.failed:
        statusColor = Colors.red;
        statusText = 'Sync failed';
        statusIcon = Icons.error;
        break;
    }

    return Row(
      children: [
        Icon(statusIcon, color: statusColor, size: 16),
        const SizedBox(width: 8),
        Text(
          statusText,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: statusColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPendingItemsRow(BuildContext context, SyncState syncState) {
    return Row(
      children: [
        const Icon(Icons.upload, color: Colors.orange, size: 16),
        const SizedBox(width: 8),
        Text(
          '${syncState.pendingItemsCount} items pending sync',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorRow(BuildContext context, String errorMessage) {
    return Row(
      children: [
        const Icon(Icons.warning, color: Colors.red, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            errorMessage,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.red,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _testBackendEndpoints(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('Testing Backend Endpoints'),
        content: SizedBox(
          width: 300,
          height: 100,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );

    try {
      final results = await BackendTestService.testAllEndpoints();
      
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Backend Test Results'),
            content: SizedBox(
              width: 400,
              height: 400,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: results.entries.map((entry) {
                    final result = entry.value;
                    final isSuccess = result['status'] == 'success';
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: isSuccess ? Colors.green.shade50 : Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('Status: ${result['status']}'),
                            if (result['statusCode'] != null)
                              Text('Code: ${result['statusCode']}'),
                            if (result['error'] != null)
                              Text('Error: ${result['error']}', 
                                   style: const TextStyle(color: Colors.red)),
                            if (result['data'] != null && result['data'].toString().isNotEmpty)
                              Text('Response: ${result['data']}'),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _testSimpleConnection() async {
    // This will print results to console/debug output
    await SimpleConnectivityTest.testConnection();
  }
}

class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);
    
    if (syncState.pendingItemsCount == 0 && syncState.syncStatus == SyncStatus.synced) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getIndicatorColor(syncState).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getIndicatorColor(syncState).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (syncState.isSyncing)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: _getIndicatorColor(syncState),
              ),
            )
          else
            Icon(
              _getIndicatorIcon(syncState),
              size: 12,
              color: _getIndicatorColor(syncState),
            ),
          const SizedBox(width: 4),
          Text(
            syncState.pendingItemsCount > 0 
                ? '${syncState.pendingItemsCount}' 
                : _getStatusText(syncState),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _getIndicatorColor(syncState),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Color _getIndicatorColor(SyncState syncState) {
    if (!syncState.isConnected) return Colors.red;
    
    switch (syncState.syncStatus) {
      case SyncStatus.pending:
        return Colors.orange;
      case SyncStatus.syncing:
        return Colors.blue;
      case SyncStatus.synced:
        return Colors.green;
      case SyncStatus.failed:
        return Colors.red;
    }
  }

  IconData _getIndicatorIcon(SyncState syncState) {
    if (!syncState.isConnected) return Icons.wifi_off;
    
    switch (syncState.syncStatus) {
      case SyncStatus.pending:
        return Icons.schedule;
      case SyncStatus.syncing:
        return Icons.sync;
      case SyncStatus.synced:
        return Icons.check_circle;
      case SyncStatus.failed:
        return Icons.error;
    }
  }

  String _getStatusText(SyncState syncState) {
    if (!syncState.isConnected) return 'Offline';
    
    switch (syncState.syncStatus) {
      case SyncStatus.pending:
        return 'Pending';
      case SyncStatus.syncing:
        return 'Syncing';
      case SyncStatus.synced:
        return 'Synced';
      case SyncStatus.failed:
        return 'Failed';
    }
  }
}