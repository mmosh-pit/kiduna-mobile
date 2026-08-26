import '../../../core/utils/logger.dart';
import '../../../data/services/gravity_service.dart';
import 'field_models.dart';
import 'field_source.dart';
import 'gravity_snapshot_converter.dart';

/// A [FieldSource] that fetches live gravity data from the API and
/// converts it to a [FieldSnapshot]. Returns an empty snapshot
/// when the wallet is unavailable or the API call fails.
class GravityFieldSource with FieldEventSink implements FieldSource {
  GravityFieldSource({
    required this.walletAddress,
    required this.viewerName,
    this.currentRealmId,
  });

  final String walletAddress;
  final String viewerName;
  final String? currentRealmId;

  @override
  Future<FieldSnapshot> load() async {
    AppLogger.debug(
      'load() called — wallet="${walletAddress.isEmpty ? "(empty)" : walletAddress.substring(0, 8)}…", viewer="$viewerName"',
      tag: 'GravityFieldSource',
    );

    if (walletAddress.isEmpty) {
      AppLogger.warning(
        'No wallet — returning empty snapshot',
        tag: 'GravityFieldSource',
      );
      return _emptySnapshot();
    }

    try {
      AppLogger.debug(
        'Calling GET /api/gravity/$walletAddress',
        tag: 'GravityFieldSource',
      );
      final gravity = await GravityService.instance.fetchGravity(
        walletAddress,
        currentRealmId: currentRealmId,
      );

      if (gravity.realms.isEmpty) {
        if (currentRealmId != null) {
          AppLogger.info(
            'No nested realms for $currentRealmId — returning empty snapshot',
            tag: 'GravityFieldSource',
          );
          return gravityToSnapshot(
            gravity: gravity,
            viewerId: walletAddress,
            viewerName: viewerName,
          );
        }
        AppLogger.warning(
          'Gravity returned 0 realms — returning empty snapshot',
          tag: 'GravityFieldSource',
        );
        return _emptySnapshot();
      }

      AppLogger.info(
        'Gravity loaded: ${gravity.realms.length} realms for wallet ${walletAddress.substring(0, 8)}…',
        tag: 'GravityFieldSource',
      );

      return gravityToSnapshot(
        gravity: gravity,
        viewerId: walletAddress,
        viewerName: viewerName,
      );
    } catch (e, st) {
      AppLogger.error(
        'Gravity fetch failed',
        tag: 'GravityFieldSource',
        error: e,
        stackTrace: st,
      );
      if (currentRealmId != null) {
        return FieldSnapshot(
          schemaVersion: '1.0',
          viewer: Viewer(
            id: walletAddress,
            displayName: viewerName,
          ),
          ecosystem: const EcosystemRef(
            id: 'kinship-duna',
            name: 'Kinship Duna',
            type: 'Ecosystem',
          ),
          realms: const [],
          clusters: const [],
        );
      }
      return _emptySnapshot();
    }
  }

  FieldSnapshot _emptySnapshot() => FieldSnapshot(
        schemaVersion: '1.0',
        viewer: Viewer(
          id: walletAddress.isNotEmpty ? walletAddress : 'unknown',
          displayName: viewerName,
        ),
        ecosystem: const EcosystemRef(
          id: 'kinship-duna',
          name: 'Kinship Duna',
          type: 'Ecosystem',
        ),
        realms: const [],
        clusters: const [],
      );
}
