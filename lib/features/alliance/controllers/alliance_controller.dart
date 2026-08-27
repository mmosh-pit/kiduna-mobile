import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/realm_model.dart';
import '../../../data/services/realm_service.dart';
import '../../auth/controllers/auth_controller.dart';

/// State for the alliance feature.
class AllianceState {
  const AllianceState({
    this.alliances = const [],
    this.isLoading = false,
    this.error,
    this.proposals = const [],
    this.proposalsLoading = false,
    this.walletBalance,
    this.walletTransactions = const [],
  });

  final List<RealmModel> alliances;
  final bool isLoading;
  final String? error;
  final List<Map<String, dynamic>> proposals;
  final bool proposalsLoading;
  final Map<String, dynamic>? walletBalance;
  final List<Map<String, dynamic>> walletTransactions;

  AllianceState copyWith({
    List<RealmModel>? alliances,
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<Map<String, dynamic>>? proposals,
    bool? proposalsLoading,
    Map<String, dynamic>? walletBalance,
    List<Map<String, dynamic>>? walletTransactions,
  }) {
    return AllianceState(
      alliances: alliances ?? this.alliances,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      proposals: proposals ?? this.proposals,
      proposalsLoading: proposalsLoading ?? this.proposalsLoading,
      walletBalance: walletBalance ?? this.walletBalance,
      walletTransactions: walletTransactions ?? this.walletTransactions,
    );
  }
}

/// Manages alliance data and proposals.
class AllianceController extends Notifier<AllianceState> {
  @override
  AllianceState build() {
    Future.microtask(_loadAlliances);
    return const AllianceState(isLoading: true);
  }

  String? get _token => ref.read(authControllerProvider).token;

  Future<void> _loadAlliances() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final alliances = await RealmService.instance.fetchRealms(
        type: 'alliance',
        authToken: _token,
      );
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, alliances: alliances);
    } on AppException catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, error: 'Failed to load alliances.');
      AppLogger.error('Load alliances failed', tag: 'AllianceCtrl', error: e);
    }
  }

  Future<void> refresh() => _loadAlliances();

  Future<List<RealmModel>> fetchCells(String allianceId) async {
    try {
      return await RealmService.instance.fetchRealms(
        parentId: allianceId,
        authToken: _token,
      );
    } catch (e) {
      AppLogger.error('Fetch cells failed', tag: 'AllianceCtrl', error: e);
      return [];
    }
  }

  Future<bool> updateMemberRole(
    String realmId,
    String memberId,
    String role,
  ) async {
    try {
      await RealmService.instance.updateMemberRole(
        realmId: realmId,
        memberId: memberId,
        role: role,
        authToken: _token,
      );
      await refresh();
      return true;
    } catch (e) {
      AppLogger.error('Update role failed', tag: 'AllianceCtrl', error: e);
      return false;
    }
  }

  // ── Proposals ──

  Future<void> loadProposals(String realmId) async {
    state = state.copyWith(proposalsLoading: true);
    try {
      final proposals = await RealmService.instance.fetchProposals(
        realmId,
        authToken: _token,
      );
      if (!ref.mounted) return;
      state = state.copyWith(
        proposalsLoading: false,
        proposals: proposals,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        proposalsLoading: false,
        proposals: const [],
      );
      AppLogger.error('Load proposals failed', tag: 'AllianceCtrl', error: e);
    }
  }

  Future<bool> createTransferProposal({
    required String realmId,
    required String to,
    required double amount,
    required bool isSol,
  }) async {
    try {
      if (isSol) {
        await RealmService.instance.createTransferSolProposal(
          realmId: realmId, to: to, amountSol: amount, authToken: _token,
        );
      } else {
        await RealmService.instance.createTransferUsdcProposal(
          realmId: realmId, to: to, amountUsdc: amount, authToken: _token,
        );
      }
      await loadProposals(realmId);
      return true;
    } catch (e) {
      AppLogger.error('Create proposal failed', tag: 'AllianceCtrl', error: e);
      return false;
    }
  }

  Future<bool> approveProposal(String realmId, String txIndex) async {
    try {
      await RealmService.instance.approveProposal(
        realmId: realmId, transactionIndex: txIndex, authToken: _token,
      );
      await loadProposals(realmId);
      return true;
    } catch (e) {
      AppLogger.error('Approve failed', tag: 'AllianceCtrl', error: e);
      return false;
    }
  }

  Future<bool> rejectProposal(String realmId, String txIndex) async {
    try {
      await RealmService.instance.rejectProposal(
        realmId: realmId, transactionIndex: txIndex, authToken: _token,
      );
      await loadProposals(realmId);
      return true;
    } catch (e) {
      AppLogger.error('Reject failed', tag: 'AllianceCtrl', error: e);
      return false;
    }
  }

  Future<bool> executeProposal(String realmId, String txIndex) async {
    try {
      await RealmService.instance.executeVaultProposal(
        realmId: realmId, transactionIndex: txIndex, authToken: _token,
      );
      await loadProposals(realmId);
      return true;
    } catch (e) {
      AppLogger.error('Execute failed', tag: 'AllianceCtrl', error: e);
      return false;
    }
  }

  Future<bool> memberProposal({
    required String realmId,
    required String wallet,
    required bool isAdd,
  }) async {
    try {
      if (isAdd) {
        await RealmService.instance.addMemberProposal(
          realmId: realmId, wallet: wallet, authToken: _token,
        );
      } else {
        await RealmService.instance.removeMemberProposal(
          realmId: realmId, wallet: wallet, authToken: _token,
        );
      }
      await loadProposals(realmId);
      return true;
    } catch (e) {
      AppLogger.error('Member proposal failed', tag: 'AllianceCtrl', error: e);
      return false;
    }
  }

  Future<bool> changeThresholdProposal({
    required String realmId,
    required int newThreshold,
  }) async {
    try {
      await RealmService.instance.changeThresholdProposal(
        realmId: realmId, newThreshold: newThreshold, authToken: _token,
      );
      await loadProposals(realmId);
      return true;
    } catch (e) {
      AppLogger.error('Threshold proposal failed', tag: 'AllianceCtrl', error: e);
      return false;
    }
  }

  // ── Wallet ──

  Future<void> loadWalletBalance(String realmId) async {
    try {
      final balance = await RealmService.instance.fetchWalletBalance(
        realmId, authToken: _token,
      );
      if (!ref.mounted) return;
      state = state.copyWith(walletBalance: balance);
    } catch (e) {
      AppLogger.error('Load balance failed', tag: 'AllianceCtrl', error: e);
    }
  }

  Future<void> loadWalletTransactions(String realmId) async {
    try {
      final txns = await RealmService.instance.fetchWalletTransactions(
        realmId, authToken: _token,
      );
      if (!ref.mounted) return;
      state = state.copyWith(walletTransactions: txns);
    } catch (e) {
      AppLogger.error('Load transactions failed', tag: 'AllianceCtrl', error: e);
    }
  }
}

final allianceControllerProvider =
    NotifierProvider<AllianceController, AllianceState>(AllianceController.new);