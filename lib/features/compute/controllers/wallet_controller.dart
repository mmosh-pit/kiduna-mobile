import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/logger.dart';
import '../../../core/wallet/phantom.dart';

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
  @override
  WalletState build() => const WalletState();

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
        // Phantom returns nothing when the user dismisses the prompt.
        state = state.copyWith(isConnecting: false);
        return;
      }
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
    state = const WalletState();
  }
}

final walletControllerProvider =
    NotifierProvider<WalletController, WalletState>(WalletController.new);
