import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sync_provider.dart';
import '../services/sync_service.dart';

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