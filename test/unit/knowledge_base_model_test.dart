import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna/data/models/knowledge_base_model.dart';

void main() {
  group('KbIngestStatus', () {
    test('fromString resolves all valid statuses', () {
      expect(KbIngestStatus.fromString('pending'), KbIngestStatus.pending);
      expect(KbIngestStatus.fromString('ingested'), KbIngestStatus.ingested);
      expect(KbIngestStatus.fromString('failed'), KbIngestStatus.failed);
    });

    test('fromString defaults unknown to pending', () {
      expect(KbIngestStatus.fromString('unknown'), KbIngestStatus.pending);
      expect(KbIngestStatus.fromString(''), KbIngestStatus.pending);
    });
  });

  group('KbStatsModel', () {
    const json = {
      'total_items': 10,
      'ingested_count': 7,
      'pending_count': 2,
      'failed_count': 1,
    };

    test('fromJson parses all fields', () {
      final stats = KbStatsModel.fromJson(json);
      expect(stats.totalItems, 10);
      expect(stats.ingestedCount, 7);
      expect(stats.pendingCount, 2);
      expect(stats.failedCount, 1);
    });

    test('fromJson defaults missing fields to zero', () {
      final stats = KbStatsModel.fromJson(const <String, dynamic>{});
      expect(stats.totalItems, 0);
      expect(stats.ingestedCount, 0);
      expect(stats.pendingCount, 0);
      expect(stats.failedCount, 0);
    });

    test('fromJson handles double values from web runtime', () {
      final stats = KbStatsModel.fromJson(const {
        'total_items': 5.0,
        'ingested_count': 3.0,
        'pending_count': 1.0,
        'failed_count': 1.0,
      });
      expect(stats.totalItems, 5);
      expect(stats.ingestedCount, 3);
    });

    test('toJson produces the expected map', () {
      final stats = KbStatsModel.fromJson(json);
      final output = stats.toJson();
      expect(output['total_items'], 10);
      expect(output['ingested_count'], 7);
      expect(output['pending_count'], 2);
      expect(output['failed_count'], 1);
    });

    test('round-trip: fromJson(toJson) produces equal objects', () {
      final original = KbStatsModel.fromJson(json);
      final roundTripped = KbStatsModel.fromJson(original.toJson());
      expect(roundTripped, equals(original));
    });

    test('equality is based on all fields', () {
      final a = KbStatsModel.fromJson(json);
      final b = KbStatsModel.fromJson(json);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('inequality when any field differs', () {
      final a = KbStatsModel.fromJson(json);
      final modified = Map<String, dynamic>.of(json)..['total_items'] = 99;
      final b = KbStatsModel.fromJson(modified);
      expect(a, isNot(equals(b)));
    });

    test('toString includes counts', () {
      final stats = KbStatsModel.fromJson(json);
      final str = stats.toString();
      expect(str, contains('KbStatsModel'));
      expect(str, contains('10'));
      expect(str, contains('7'));
    });
  });

  group('KbItemModel', () {
    const json = {
      'id': 'item_abc',
      'name': 'research.pdf',
      'type': 'file',
      'status': 'ingested',
      'chunk_count': 12,
      'source_url': 'https://drive.google.com/file/123',
      'error': null,
      'created_at': '2026-07-15T10:00:00Z',
    };

    test('fromJson parses all fields', () {
      final item = KbItemModel.fromJson(json);
      expect(item.id, 'item_abc');
      expect(item.name, 'research.pdf');
      expect(item.type, 'file');
      expect(item.status, KbIngestStatus.ingested);
      expect(item.chunkCount, 12);
      expect(item.sourceUrl, 'https://drive.google.com/file/123');
      expect(item.error, isNull);
      expect(item.createdAt, '2026-07-15T10:00:00Z');
    });

    test('fromJson defaults missing fields', () {
      final item = KbItemModel.fromJson(const <String, dynamic>{});
      expect(item.id, '');
      expect(item.name, '');
      expect(item.type, 'file');
      expect(item.status, KbIngestStatus.pending);
      expect(item.chunkCount, 0);
      expect(item.sourceUrl, isNull);
      expect(item.error, isNull);
      expect(item.createdAt, isNull);
    });

    test('fromJson handles double chunk_count from web runtime', () {
      final item = KbItemModel.fromJson(const {
        'id': 'i1',
        'name': 'doc.md',
        'chunk_count': 5.0,
      });
      expect(item.chunkCount, 5);
    });

    test('toJson produces the expected map', () {
      final item = KbItemModel.fromJson(json);
      final output = item.toJson();
      expect(output['id'], 'item_abc');
      expect(output['name'], 'research.pdf');
      expect(output['status'], 'ingested');
      expect(output['chunk_count'], 12);
      expect(output['source_url'], 'https://drive.google.com/file/123');
    });

    test('toJson omits null optional fields', () {
      final item = KbItemModel.fromJson(const {'id': 'i1', 'name': 'doc.md'});
      final output = item.toJson();
      expect(output.containsKey('source_url'), isFalse);
      expect(output.containsKey('error'), isFalse);
      expect(output.containsKey('created_at'), isFalse);
    });

    test('round-trip: fromJson(toJson) produces equal objects', () {
      final original = KbItemModel.fromJson(json);
      final roundTripped = KbItemModel.fromJson(original.toJson());
      expect(roundTripped, equals(original));
    });

    test('equality is based on all fields', () {
      final a = KbItemModel.fromJson(json);
      final b = KbItemModel.fromJson(json);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('inequality when id differs', () {
      final a = KbItemModel.fromJson(json);
      final modified = Map<String, dynamic>.of(json)..['id'] = 'other';
      final b = KbItemModel.fromJson(modified);
      expect(a, isNot(equals(b)));
    });

    test('toString includes id, name, and status', () {
      final item = KbItemModel.fromJson(json);
      final str = item.toString();
      expect(str, contains('KbItemModel'));
      expect(str, contains('item_abc'));
      expect(str, contains('research.pdf'));
      expect(str, contains('ingested'));
    });
  });

  group('KnowledgeBaseModel', () {
    const json = {
      'id': 'kb_123',
      'name': 'Research Notes',
      'wallet': 'wallet_abc',
      'platform_id': 'plat_1',
      'privacy': 'private',
      'created_at': '2026-07-01T00:00:00Z',
      'updated_at': '2026-07-15T12:00:00Z',
      'items': <dynamic>[
        {
          'id': 'item_1',
          'name': 'doc.pdf',
          'type': 'file',
          'status': 'ingested',
          'chunk_count': 5,
        },
        {
          'id': 'item_2',
          'name': 'notes.md',
          'type': 'text',
          'status': 'pending',
          'chunk_count': 0,
        },
      ],
      'stats': {
        'total_items': 2,
        'ingested_count': 1,
        'pending_count': 1,
        'failed_count': 0,
      },
    };

    test('fromJson parses all fields', () {
      final kb = KnowledgeBaseModel.fromJson(json);
      expect(kb.id, 'kb_123');
      expect(kb.name, 'Research Notes');
      expect(kb.wallet, 'wallet_abc');
      expect(kb.platformId, 'plat_1');
      expect(kb.privacy, 'private');
      expect(kb.createdAt, '2026-07-01T00:00:00Z');
      expect(kb.updatedAt, '2026-07-15T12:00:00Z');
      expect(kb.items, hasLength(2));
      expect(kb.items.first.id, 'item_1');
      expect(kb.items.last.id, 'item_2');
      expect(kb.stats, isNotNull);
      expect(kb.stats!.totalItems, 2);
    });

    test('fromJson defaults missing fields', () {
      final kb = KnowledgeBaseModel.fromJson(const <String, dynamic>{});
      expect(kb.id, '');
      expect(kb.name, '');
      expect(kb.wallet, '');
      expect(kb.platformId, isNull);
      expect(kb.privacy, 'private');
      expect(kb.createdAt, isNull);
      expect(kb.updatedAt, isNull);
      expect(kb.items, isEmpty);
      expect(kb.stats, isNull);
    });

    test('fromJson handles missing items and stats', () {
      final kb = KnowledgeBaseModel.fromJson(const {
        'id': 'kb_1',
        'name': 'Test',
        'wallet': 'w',
      });
      expect(kb.items, isEmpty);
      expect(kb.stats, isNull);
    });

    test('toJson produces the expected map', () {
      final kb = KnowledgeBaseModel.fromJson(json);
      final output = kb.toJson();
      expect(output['id'], 'kb_123');
      expect(output['name'], 'Research Notes');
      expect(output['wallet'], 'wallet_abc');
      expect(output['platform_id'], 'plat_1');
      expect(output['privacy'], 'private');
      expect(output['items'], hasLength(2));
      expect(output['stats'], isNotNull);
    });

    test('toJson omits null optional fields', () {
      final kb = KnowledgeBaseModel.fromJson(const {
        'id': 'kb_1',
        'name': 'Test',
        'wallet': 'w',
      });
      final output = kb.toJson();
      expect(output.containsKey('platform_id'), isFalse);
      expect(output.containsKey('created_at'), isFalse);
      expect(output.containsKey('updated_at'), isFalse);
      expect(output.containsKey('stats'), isFalse);
    });

    test('round-trip: fromJson(toJson) produces equal objects', () {
      final original = KnowledgeBaseModel.fromJson(json);
      final roundTripped = KnowledgeBaseModel.fromJson(original.toJson());
      expect(roundTripped, equals(original));
    });

    test('equality is based on all fields', () {
      final a = KnowledgeBaseModel.fromJson(json);
      final b = KnowledgeBaseModel.fromJson(json);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('inequality when name differs', () {
      final a = KnowledgeBaseModel.fromJson(json);
      final modified = Map<String, dynamic>.of(json)..['name'] = 'Other';
      final b = KnowledgeBaseModel.fromJson(modified);
      expect(a, isNot(equals(b)));
    });

    test('copyWith preserves fields', () {
      final kb = KnowledgeBaseModel.fromJson(json);
      final copy = kb.copyWith(name: 'Updated');
      expect(copy.name, 'Updated');
      expect(copy.id, kb.id);
      expect(copy.wallet, kb.wallet);
      expect(copy.items, kb.items);
    });

    test('copyWith clearPlatformId sets platformId to null', () {
      final kb = KnowledgeBaseModel.fromJson(json);
      expect(kb.platformId, isNotNull);
      final copy = kb.copyWith(clearPlatformId: true);
      expect(copy.platformId, isNull);
    });

    test('copyWith clearStats sets stats to null', () {
      final kb = KnowledgeBaseModel.fromJson(json);
      expect(kb.stats, isNotNull);
      final copy = kb.copyWith(clearStats: true);
      expect(copy.stats, isNull);
    });

    test('copyWith preserves platformId when not cleared', () {
      final kb = KnowledgeBaseModel.fromJson(json);
      final copy = kb.copyWith(name: 'Updated');
      expect(copy.platformId, 'plat_1');
    });

    test('toString includes id, name, and item count', () {
      final kb = KnowledgeBaseModel.fromJson(json);
      final str = kb.toString();
      expect(str, contains('KnowledgeBaseModel'));
      expect(str, contains('kb_123'));
      expect(str, contains('Research Notes'));
      expect(str, contains('2'));
    });
  });
}
