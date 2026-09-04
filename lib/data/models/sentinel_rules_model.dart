import 'package:flutter/foundation.dart';

/// Custom game rules a Cell steward can set to govern gameplay.
///
/// Stored inside the Realm's `config` jsonb under the `sentinelRules` key.
/// All fields are optional — a creator sets only the rules they care about;
/// unset fields inherit engine defaults.
@immutable
class SentinelRules {
  const SentinelRules({
    this.principles = const [],
    this.description,
    this.startingStack,
    this.maxBetAmount,
    this.minBetAmount,
    this.maxRaisesPerRound,
    this.turnTimeoutSeconds,
    this.maxPlayersPerTable,
    this.customAnteLevels,
    this.maxHoleCards,
    this.compChipsPerPlayer,
    this.powerDeckSize,
    this.customChipSellValue,
    this.levelDurationSeconds,
    this.bannedPowerCards = const [],
    this.bannedCourtMembers = const [],
    this.bannedItems = const [],
    this.allowedClasses,
    this.enablePowerCards,
    this.enableItems,
    this.enableJokers,
    this.enableSuddenDeath,
    this.enableHeatingUp,
    this.enableTilt,
    this.enableStealth,
    this.allowFoldOnly,
    this.timedLevels,
    this.createdBy,
    this.updatedAt,
  });

  // ── Principles (visible text rules) ──

  final List<String> principles;
  final String? description;

  // ── Constraints (game mechanic limits) ──

  final int? startingStack;
  final int? maxBetAmount;
  final int? minBetAmount;
  final int? maxRaisesPerRound;
  final int? turnTimeoutSeconds;
  final int? maxPlayersPerTable;
  final List<int>? customAnteLevels;
  final int? maxHoleCards;
  final int? compChipsPerPlayer;
  final int? powerDeckSize;
  final int? customChipSellValue;
  final int? levelDurationSeconds;

  // ── Guardrails (ban / restrict) ──

  final List<String> bannedPowerCards;
  final List<String> bannedCourtMembers;
  final List<String> bannedItems;
  final List<String>? allowedClasses;
  final bool? enablePowerCards;
  final bool? enableItems;
  final bool? enableJokers;
  final bool? enableSuddenDeath;
  final bool? enableHeatingUp;
  final bool? enableTilt;
  final bool? enableStealth;
  final bool? allowFoldOnly;
  final bool? timedLevels;

  // ── Meta ──

  final String? createdBy;
  final DateTime? updatedAt;

  static const SentinelRules empty = SentinelRules();

  bool get isEmpty =>
      principles.isEmpty &&
      description == null &&
      startingStack == null &&
      maxBetAmount == null &&
      minBetAmount == null &&
      maxRaisesPerRound == null &&
      turnTimeoutSeconds == null &&
      maxPlayersPerTable == null &&
      customAnteLevels == null &&
      maxHoleCards == null &&
      compChipsPerPlayer == null &&
      powerDeckSize == null &&
      customChipSellValue == null &&
      levelDurationSeconds == null &&
      bannedPowerCards.isEmpty &&
      bannedCourtMembers.isEmpty &&
      bannedItems.isEmpty &&
      allowedClasses == null &&
      enablePowerCards == null &&
      enableItems == null &&
      enableJokers == null &&
      enableSuddenDeath == null &&
      enableHeatingUp == null &&
      enableTilt == null &&
      enableStealth == null &&
      allowFoldOnly == null &&
      timedLevels == null;

  bool get isNotEmpty => !isEmpty;

  factory SentinelRules.fromJson(Map<String, dynamic> json) {
    return SentinelRules(
      principles: (json['principles'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const [],
      description: json['description'] as String?,
      startingStack: json['startingStack'] as int?,
      maxBetAmount: json['maxBetAmount'] as int?,
      minBetAmount: json['minBetAmount'] as int?,
      maxRaisesPerRound: json['maxRaisesPerRound'] as int?,
      turnTimeoutSeconds: json['turnTimeoutSeconds'] as int?,
      maxPlayersPerTable: json['maxPlayersPerTable'] as int?,
      customAnteLevels: (json['customAnteLevels'] as List<dynamic>?)
          ?.whereType<num>()
          .map((e) => e.toInt())
          .toList(),
      maxHoleCards: json['maxHoleCards'] as int?,
      compChipsPerPlayer: json['compChipsPerPlayer'] as int?,
      powerDeckSize: json['powerDeckSize'] as int?,
      customChipSellValue: json['customChipSellValue'] as int?,
      levelDurationSeconds: json['levelDurationSeconds'] as int?,
      bannedPowerCards: (json['bannedPowerCards'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const [],
      bannedCourtMembers: (json['bannedCourtMembers'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const [],
      bannedItems: (json['bannedItems'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const [],
      allowedClasses: (json['allowedClasses'] as List<dynamic>?)
          ?.whereType<String>()
          .toList(),
      enablePowerCards: json['enablePowerCards'] as bool?,
      enableItems: json['enableItems'] as bool?,
      enableJokers: json['enableJokers'] as bool?,
      enableSuddenDeath: json['enableSuddenDeath'] as bool?,
      enableHeatingUp: json['enableHeatingUp'] as bool?,
      enableTilt: json['enableTilt'] as bool?,
      enableStealth: json['enableStealth'] as bool?,
      allowFoldOnly: json['allowFoldOnly'] as bool?,
      timedLevels: json['timedLevels'] as bool?,
      createdBy: json['createdBy'] as String?,
      updatedAt: json['updatedAt'] is String
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    if (principles.isNotEmpty) {
      json['principles'] = principles;
    }
    if (description != null) {
      json['description'] = description;
    }
    if (startingStack != null) {
      json['startingStack'] = startingStack;
    }
    if (maxBetAmount != null) {
      json['maxBetAmount'] = maxBetAmount;
    }
    if (minBetAmount != null) {
      json['minBetAmount'] = minBetAmount;
    }
    if (maxRaisesPerRound != null) {
      json['maxRaisesPerRound'] = maxRaisesPerRound;
    }
    if (turnTimeoutSeconds != null) {
      json['turnTimeoutSeconds'] = turnTimeoutSeconds;
    }
    if (maxPlayersPerTable != null) {
      json['maxPlayersPerTable'] = maxPlayersPerTable;
    }
    if (customAnteLevels != null) {
      json['customAnteLevels'] = customAnteLevels;
    }
    if (maxHoleCards != null) {
      json['maxHoleCards'] = maxHoleCards;
    }
    if (compChipsPerPlayer != null) {
      json['compChipsPerPlayer'] = compChipsPerPlayer;
    }
    if (powerDeckSize != null) {
      json['powerDeckSize'] = powerDeckSize;
    }
    if (customChipSellValue != null) {
      json['customChipSellValue'] = customChipSellValue;
    }
    if (levelDurationSeconds != null) {
      json['levelDurationSeconds'] = levelDurationSeconds;
    }
    if (bannedPowerCards.isNotEmpty) {
      json['bannedPowerCards'] = bannedPowerCards;
    }
    if (bannedCourtMembers.isNotEmpty) {
      json['bannedCourtMembers'] = bannedCourtMembers;
    }
    if (bannedItems.isNotEmpty) {
      json['bannedItems'] = bannedItems;
    }
    if (allowedClasses != null) {
      json['allowedClasses'] = allowedClasses;
    }
    if (enablePowerCards != null) {
      json['enablePowerCards'] = enablePowerCards;
    }
    if (enableItems != null) {
      json['enableItems'] = enableItems;
    }
    if (enableJokers != null) {
      json['enableJokers'] = enableJokers;
    }
    if (enableSuddenDeath != null) {
      json['enableSuddenDeath'] = enableSuddenDeath;
    }
    if (enableHeatingUp != null) {
      json['enableHeatingUp'] = enableHeatingUp;
    }
    if (enableTilt != null) {
      json['enableTilt'] = enableTilt;
    }
    if (enableStealth != null) {
      json['enableStealth'] = enableStealth;
    }
    if (allowFoldOnly != null) {
      json['allowFoldOnly'] = allowFoldOnly;
    }
    if (timedLevels != null) {
      json['timedLevels'] = timedLevels;
    }
    if (createdBy != null) {
      json['createdBy'] = createdBy;
    }
    if (updatedAt != null) {
      json['updatedAt'] = updatedAt!.toIso8601String();
    }
    return json;
  }

  SentinelRules copyWith({
    List<String>? principles,
    String? description,
    bool clearDescription = false,
    int? startingStack,
    bool clearStartingStack = false,
    int? maxBetAmount,
    bool clearMaxBetAmount = false,
    int? minBetAmount,
    bool clearMinBetAmount = false,
    int? maxRaisesPerRound,
    bool clearMaxRaisesPerRound = false,
    int? turnTimeoutSeconds,
    bool clearTurnTimeoutSeconds = false,
    int? maxPlayersPerTable,
    bool clearMaxPlayersPerTable = false,
    List<int>? customAnteLevels,
    bool clearCustomAnteLevels = false,
    int? maxHoleCards,
    bool clearMaxHoleCards = false,
    int? compChipsPerPlayer,
    bool clearCompChipsPerPlayer = false,
    int? powerDeckSize,
    bool clearPowerDeckSize = false,
    int? customChipSellValue,
    bool clearCustomChipSellValue = false,
    int? levelDurationSeconds,
    bool clearLevelDurationSeconds = false,
    List<String>? bannedPowerCards,
    List<String>? bannedCourtMembers,
    List<String>? bannedItems,
    List<String>? allowedClasses,
    bool clearAllowedClasses = false,
    bool? enablePowerCards,
    bool clearEnablePowerCards = false,
    bool? enableItems,
    bool clearEnableItems = false,
    bool? enableJokers,
    bool clearEnableJokers = false,
    bool? enableSuddenDeath,
    bool clearEnableSuddenDeath = false,
    bool? enableHeatingUp,
    bool clearEnableHeatingUp = false,
    bool? enableTilt,
    bool clearEnableTilt = false,
    bool? enableStealth,
    bool clearEnableStealth = false,
    bool? allowFoldOnly,
    bool clearAllowFoldOnly = false,
    bool? timedLevels,
    bool clearTimedLevels = false,
    String? createdBy,
    bool clearCreatedBy = false,
    DateTime? updatedAt,
    bool clearUpdatedAt = false,
  }) {
    return SentinelRules(
      principles: principles ?? this.principles,
      description:
          clearDescription ? null : (description ?? this.description),
      startingStack:
          clearStartingStack ? null : (startingStack ?? this.startingStack),
      maxBetAmount:
          clearMaxBetAmount ? null : (maxBetAmount ?? this.maxBetAmount),
      minBetAmount:
          clearMinBetAmount ? null : (minBetAmount ?? this.minBetAmount),
      maxRaisesPerRound: clearMaxRaisesPerRound
          ? null
          : (maxRaisesPerRound ?? this.maxRaisesPerRound),
      turnTimeoutSeconds: clearTurnTimeoutSeconds
          ? null
          : (turnTimeoutSeconds ?? this.turnTimeoutSeconds),
      maxPlayersPerTable: clearMaxPlayersPerTable
          ? null
          : (maxPlayersPerTable ?? this.maxPlayersPerTable),
      customAnteLevels: clearCustomAnteLevels
          ? null
          : (customAnteLevels ?? this.customAnteLevels),
      maxHoleCards:
          clearMaxHoleCards ? null : (maxHoleCards ?? this.maxHoleCards),
      compChipsPerPlayer: clearCompChipsPerPlayer
          ? null
          : (compChipsPerPlayer ?? this.compChipsPerPlayer),
      powerDeckSize:
          clearPowerDeckSize ? null : (powerDeckSize ?? this.powerDeckSize),
      customChipSellValue: clearCustomChipSellValue
          ? null
          : (customChipSellValue ?? this.customChipSellValue),
      levelDurationSeconds: clearLevelDurationSeconds
          ? null
          : (levelDurationSeconds ?? this.levelDurationSeconds),
      bannedPowerCards: bannedPowerCards ?? this.bannedPowerCards,
      bannedCourtMembers: bannedCourtMembers ?? this.bannedCourtMembers,
      bannedItems: bannedItems ?? this.bannedItems,
      allowedClasses: clearAllowedClasses
          ? null
          : (allowedClasses ?? this.allowedClasses),
      enablePowerCards: clearEnablePowerCards
          ? null
          : (enablePowerCards ?? this.enablePowerCards),
      enableItems:
          clearEnableItems ? null : (enableItems ?? this.enableItems),
      enableJokers:
          clearEnableJokers ? null : (enableJokers ?? this.enableJokers),
      enableSuddenDeath: clearEnableSuddenDeath
          ? null
          : (enableSuddenDeath ?? this.enableSuddenDeath),
      enableHeatingUp: clearEnableHeatingUp
          ? null
          : (enableHeatingUp ?? this.enableHeatingUp),
      enableTilt:
          clearEnableTilt ? null : (enableTilt ?? this.enableTilt),
      enableStealth:
          clearEnableStealth ? null : (enableStealth ?? this.enableStealth),
      allowFoldOnly:
          clearAllowFoldOnly ? null : (allowFoldOnly ?? this.allowFoldOnly),
      timedLevels:
          clearTimedLevels ? null : (timedLevels ?? this.timedLevels),
      createdBy:
          clearCreatedBy ? null : (createdBy ?? this.createdBy),
      updatedAt:
          clearUpdatedAt ? null : (updatedAt ?? this.updatedAt),
    );
  }
}
