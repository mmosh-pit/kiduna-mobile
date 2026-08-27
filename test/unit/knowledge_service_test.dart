import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna/data/models/knowledge_base_model.dart';

/// KnowledgeService integration tests require a running backend and Dio setup.
/// These tests validate the response shapes the service parses — the same
/// JSON structures returned by the Knowledge API endpoints.
void main() {
  group('KnowledgeBaseModel response parsing', () {
    test('parses the list endpoint response (wrapped format)', () {
      const listResponse = {
        'knowledgeBases': <dynamic>[
          {
            'id': 'kb_001',
            'name': 'Research Notes',
            'wallet': 'wallet_abc',
            'privacy': 'private',
            'createdAt': '2026-07-01T00:00:00Z',
            'updatedAt': '2026-07-15T12:00:00Z',
          },
          {
            'id': 'kb_002',
            'name': 'Product Docs',
            'wallet': 'wallet_abc',
            'platformId': 'plat_1',
            'privacy': 'shared',
          },
        ],
        'total': 2,
      };

      final kbList = listResponse['knowledgeBases'] as List<dynamic>? ?? [];
      final kbs = kbList
          .map((e) => KnowledgeBaseModel.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(kbs, hasLength(2));
      expect(kbs.first.id, 'kb_001');
      expect(kbs.first.name, 'Research Notes');
      expect(kbs.first.privacy, 'private');
      expect(kbs.first.createdAt, '2026-07-01T00:00:00Z');
      expect(kbs.last.id, 'kb_002');
      expect(kbs.last.platformId, 'plat_1');
      expect(kbs.last.privacy, 'shared');
    });

    test('parses the detail endpoint response with items', () {
      const detailResponse = {
        'id': 'kb_001',
        'name': 'Research Notes',
        'privacy': 'private',
        'createdAt': '2026-07-01T00:00:00Z',
        'updatedAt': '2026-07-15T12:00:00Z',
        'itemCount': 3,
        'items': <dynamic>[
          {
            'id': 'item_1',
            'name': 'paper.pdf',
            'type': 'file',
            'status': 'ingested',
            'createdAt': '2026-07-01T00:00:00Z',
          },
          {
            'id': 'item_2',
            'name': 'notes.md',
            'type': 'text',
            'status': 'pending',
          },
          {
            'id': 'item_3',
            'name': 'broken.doc',
            'type': 'file',
            'status': 'failed',
            'error': 'Unsupported format',
          },
        ],
      };

      final kb = KnowledgeBaseModel.fromJson(detailResponse);

      expect(kb.id, 'kb_001');
      expect(kb.createdAt, '2026-07-01T00:00:00Z');
      expect(kb.items, hasLength(3));
      expect(kb.items[0].status, KbIngestStatus.ingested);
      expect(kb.items[0].createdAt, '2026-07-01T00:00:00Z');
      expect(kb.items[1].status, KbIngestStatus.pending);
      expect(kb.items[2].status, KbIngestStatus.failed);
      expect(kb.items[2].error, 'Unsupported format');
    });

    test('parses create endpoint response', () {
      const createResponse = {
        'id': 'kb_new',
        'name': 'My New KB',
        'namespace': 'my-new-kb-abc123',
        'privacy': 'private',
        'containerIds': <dynamic>[],
        'createdAt': '2026-08-01T10:00:00Z',
        'itemCount': 0,
      };

      final kb = KnowledgeBaseModel.fromJson(createResponse);

      expect(kb.id, 'kb_new');
      expect(kb.name, 'My New KB');
      expect(kb.createdAt, '2026-08-01T10:00:00Z');
      expect(kb.items, isEmpty);
    });

    test('handles empty list response', () {
      const emptyResponse = {'knowledgeBases': <dynamic>[], 'total': 0};

      final kbList = emptyResponse['knowledgeBases'] as List<dynamic>? ?? [];
      final kbs = kbList
          .map((e) => KnowledgeBaseModel.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(kbs, isEmpty);
    });

    test('handles response with double values from web runtime', () {
      const json = {
        'id': 'kb_web',
        'name': 'Web KB',
        'wallet': 'w',
        'items': <dynamic>[
          {'id': 'i1', 'name': 'doc.pdf', 'chunk_count': 8.0},
        ],
        'stats': {
          'total_items': 1.0,
          'ingested_count': 1.0,
          'pending_count': 0.0,
          'failed_count': 0.0,
        },
      };

      final kb = KnowledgeBaseModel.fromJson(json);

      expect(kb.items.first.chunkCount, 8);
      expect(kb.stats!.totalItems, 1);
      expect(kb.stats!.ingestedCount, 1);
    });

    test('ignores unknown keys in the response', () {
      const json = {
        'id': 'kb_1',
        'name': 'Test',
        'wallet': 'w',
        'unknownField': 'ignored',
        'anotherUnknown': 42,
      };

      final kb = KnowledgeBaseModel.fromJson(json);

      expect(kb.id, 'kb_1');
      expect(kb.name, 'Test');
    });
  });

  group('Drive import response parsing', () {
    test('parses a successful drive import item', () {
      const json = {
        'id': 'item_drive_1',
        'name': 'meeting-notes.pdf',
        'type': 'file',
        'status': 'pending',
        'createdAt': '2026-08-01T10:00:00Z',
        'url': 'https://drive.google.com/file/d/abc123',
      };

      final item = KbItemModel.fromJson(json);

      expect(item.id, 'item_drive_1');
      expect(item.name, 'meeting-notes.pdf');
      expect(item.status, KbIngestStatus.pending);
      expect(item.sourceUrl, contains('drive.google.com'));
      expect(item.createdAt, '2026-08-01T10:00:00Z');
    });
  });
}
