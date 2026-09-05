import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/logger.dart';
import '../../../core/wallet/phantom.dart';
import '../../../data/local/secure_storage.dart';

@immutable
class WalletState {
  const WalletState({
    this.address,
    this.isConnecting = false,
    this.error,
  });

  /// Public key of the connected wallet, null when not connected.
  final String? address;
  final bool isConnecting;
  final String? error;

  bool get isConnected => address != null && address!.isNotEmpty;

  /// Whether a browser wallet extension is present at all.
  bool get isAvailable => PhantomWallet.isAvailable;

  String get shortAddress {
    final a = address;
    if (a == null || a.length <= 12) return a ?? '';
    return '${a.substring(0, 4)}…${a.substring(a.length - 4)}';
  }

  WalletState copyWith({
    String? address,
    bool? isConnecting,
    String? error,
    bool clearAddress = false,
    bool clearError = false,
  }) {
    return WalletState(
      address: clearAddress ? null : (address ?? this.address),
      isConnecting: isConnecting ?? this.isConnecting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Connection state for the user's browser wallet.
///
/// Only meaningful on web — on other platforms [WalletState.isAvailable] is
/// false and connecting is a no-op.
class WalletController extends Notifier<WalletState> {
  static const _disconnectedKey = 'wallet_disconnected';

  @override
  WalletState build() {
    _eagerConnect();
    return const WalletState();
  }

  /// Silently reconnect if the user previously approved this site
  /// AND has not explicitly disconnected.
  Future<void> _eagerConnect() async {
    if (!PhantomWallet.isAvailable) return;

    try {
      // User explicitly disconnected — don't auto-reconnect.
      final disconnected =
          await SecureStorage.instance.read(_disconnectedKey);
      if (disconnected == 'true') return;

      final address = await PhantomWallet.eagerConnect();
      if (address != null && address.isNotEmpty) {
        state = state.copyWith(address: address);
        AppLogger.info('Wallet auto-reconnected: $address', tag: 'Wallet');
      }
    } catch (e) {
      AppLogger.warning('Wallet eager connect failed: $e', tag: 'Wallet');
    }
  }

  Future<void> connect() async {
    if (!PhantomWallet.isAvailable) {
      state = state.copyWith(
        error: 'Phantom wallet not found. Install it to continue.',
      );
      return;
    }

    state = state.copyWith(isConnecting: true, clearError: true);

    try {
      final address = await PhantomWallet.connect();
      if (address == null || address.isEmpty) {
        state = state.copyWith(isConnecting: false);
        return;
      }
      // Clear the disconnected flag — user explicitly reconnected.
      await SecureStorage.instance.delete(_disconnectedKey);
      state = state.copyWith(address: address, isConnecting: false);
      AppLogger.info('Wallet connected: $address', tag: 'Wallet');
    } catch (e, st) {
      AppLogger.error('Wallet connect failed', error: e, stackTrace: st);
      state = state.copyWith(
        isConnecting: false,
        error: 'Could not connect to your wallet.',
      );
    }
  }

  Future<void> disconnect() async {
    await PhantomWallet.disconnect();
    // Persist that the user chose to disconnect — prevents auto-reconnect.
    await SecureStorage.instance.write(_disconnectedKey, 'true');
    state = const WalletState();
  }
}

final walletControllerProvider =
    NotifierProvider<WalletController, WalletState>(WalletController.new);
