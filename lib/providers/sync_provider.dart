import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sync_service.dart';
import '../services/connectivity_service.dart';

class SyncState {
  final bool isConnected;
  final bool isSyncing;
  final SyncStatus syncStatus;
  final int pendingItemsCount;
  final String? errorMessage;

  SyncState({
    required this.isConnected,
    required this.isSyncing,
    required this.syncStatus,
    required this.pendingItemsCount,
    this.errorMessage,
  });

  SyncState copyWith({
    bool? isConnected,
    bool? isSyncing,
    SyncStatus? syncStatus,
    int? pendingItemsCount,
    String? errorMessage,
  }) {
    return SyncState(
      isConnected: isConnected ?? this.isConnected,
      isSyncing: isSyncing ?? this.isSyncing,
      syncStatus: syncStatus ?? this.syncStatus,
      pendingItemsCount: pendingItemsCount ?? this.pendingItemsCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class SyncNotifier extends StateNotifier<SyncState> {
  final SyncService _syncService = SyncService();

  SyncNotifier() : super(SyncState(
    isConnected: false,
    isSyncing: false,
    syncStatus: SyncStatus.pending,
    pendingItemsCount: 0,
  )) {
    _init();
  }

  Future<void> _init() async {
    await _syncService.initialize();
    
    ConnectivityService.connectivityStream.listen((isConnected) {
      state = state.copyWith(isConnected: isConnected);
      if (isConnected) {
        _updatePendingCount();
      }
    });
    
    _syncService.syncStatusStream.listen((syncStatus) {
      state = state.copyWith(
        syncStatus: syncStatus,
        isSyncing: syncStatus == SyncStatus.syncing,
      );
      
      if (syncStatus == SyncStatus.synced || syncStatus == SyncStatus.failed) {
        _updatePendingCount();
      }
    });
    
    state = state.copyWith(isConnected: ConnectivityService.isConnected);
    _updatePendingCount();
  }

  Future<void> _updatePendingCount() async {
    final count = await _syncService.getPendingItemsCount();
    state = state.copyWith(pendingItemsCount: count);
  }

  Future<void> syncNow() async {
    if (!state.isConnected) {
      state = state.copyWith(errorMessage: 'No internet connection');
      return;
    }
    
    await _syncService.syncPendingData();
    // Force update pending count after sync
    await _updatePendingCount();
  }

  Future<void> forceSyncAll() async {
    if (!state.isConnected) {
      state = state.copyWith(errorMessage: 'No internet connection');
      return;
    }
    
    await _syncService.forceSyncAll();
    // Force update pending count after sync
    await _updatePendingCount();
  }

  Future<void> markForSync(String table, String id) async {
    await _syncService.markForSync(table, id);
    _updatePendingCount();
  }

  Future<void> refreshPendingCount() async {
    await _updatePendingCount();
  }

  @override
  void dispose() {
    _syncService.dispose();
    super.dispose();
  }
}

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier();
});