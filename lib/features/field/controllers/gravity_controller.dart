import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/gravity_model.dart';
import '../../../data/services/gravity_service.dart';

@immutable
class GravityState {
  const GravityState({
    this.isLoading = false,
    this.error,
    this.data,
  });

  final bool isLoading;
  final String? error;
  final GravityResponse? data;

  GravityState copyWith({
    bool? isLoading,
    String? error,
    GravityResponse? data,
    bool clearError = false,
  }) {
    return GravityState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      data: data ?? this.data,
    );
  }
}

class GravityController extends Notifier<GravityState> {
  @override
  GravityState build() {
    return const GravityState();
  }

  Future<void> load(String walletAddress) async {
    if (walletAddress.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        error: 'No wallet address available.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response =
          await GravityService.instance.fetchGravity(walletAddress);
      if (!ref.mounted) return;
      state = GravityState(data: response);
    } on NetworkException catch (e) {
      if (!ref.mounted) return;
      AppLogger.warning(
        'Gravity load failed: $e',
        tag: 'GravityController',
      );
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to load realm data. Please check your connection.',
      );
    } on AppException catch (e) {
      if (!ref.mounted) return;
      AppLogger.warning(
        'Gravity load failed: $e',
        tag: 'GravityController',
      );
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      if (!ref.mounted) return;
      AppLogger.error(
        'Gravity load unexpected error',
        tag: 'GravityController',
        error: e,
      );
      state = state.copyWith(
        isLoading: false,
        error: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> retry(String walletAddress) => load(walletAddress);
}

final gravityControllerProvider =
    NotifierProvider<GravityController, GravityState>(
  GravityController.new,
);
