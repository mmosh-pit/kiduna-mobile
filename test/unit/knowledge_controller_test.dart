import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna_mobile/data/models/knowledge_base_model.dart';
import 'package:kiduna_mobile/features/field/controllers/knowledge_controller.dart';

void main() {
  group('KnowledgeState', () {
    test('initial state has no KBs, no error, and is not loading', () {
      const state = KnowledgeState();
      expect(state.isLoading, isFalse);
      expect(state.isUploading, isFalse);
      expect(state.isImportingDrive, isFalse);
      expect(state.error, isNull);
      expect(state.knowledgeBases, isEmpty);
      expect(state.activeKb, isNull);
      expect(state.driveImportTotal, 0);
      expect(state.driveImportDone, 0);
    });

    test('copyWith preserves existing error when clearError is false', () {
      const state = KnowledgeState(error: 'failed');
      final next = state.copyWith(isLoading: true);
      expect(next.error, 'failed');
      expect(next.isLoading, isTrue);
    });

    test('copyWith clears error when clearError is true', () {
      const state = KnowledgeState(error: 'failed');
      final next = state.copyWith(isLoading: true, clearError: true);
      expect(next.error, isNull);
      expect(next.isLoading, isTrue);
    });

    test('copyWith clearActiveKb sets activeKb to null', () {
      final kb = KnowledgeBaseModel.fromJson(const {
        'id': 'kb_1',
        'name': 'My KB',
        'wallet': 'w1',
      });
      final state = KnowledgeState(activeKb: kb);
      final next = state.copyWith(clearActiveKb: true);
      expect(next.activeKb, isNull);
    });

    test('copyWith preserves activeKb when not cleared', () {
      final kb = KnowledgeBaseModel.fromJson(const {
        'id': 'kb_1',
        'name': 'My KB',
        'wallet': 'w1',
      });
      final state = KnowledgeState(activeKb: kb);
      final next = state.copyWith(isLoading: false);
      expect(next.activeKb, equals(kb));
    });

    test('copyWith updates knowledgeBases', () {
      const state = KnowledgeState();
      final kbs = [
        KnowledgeBaseModel.fromJson(const {
          'id': 'kb_1',
          'name': 'KB One',
          'wallet': 'w1',
        }),
        KnowledgeBaseModel.fromJson(const {
          'id': 'kb_2',
          'name': 'KB Two',
          'wallet': 'w1',
        }),
      ];
      final next = state.copyWith(knowledgeBases: kbs);
      expect(next.knowledgeBases, hasLength(2));
      expect(next.knowledgeBases.first.id, 'kb_1');
      expect(next.knowledgeBases.last.id, 'kb_2');
    });

    test('loading state pattern: loading with clearError', () {
      const state = KnowledgeState(error: 'old error');
      final loading = state.copyWith(isLoading: true, clearError: true);
      expect(loading.isLoading, isTrue);
      expect(loading.error, isNull);
    });

    test('uploading state pattern: isUploading without clearing error', () {
      const state = KnowledgeState();
      final uploading = state.copyWith(isUploading: true, clearError: true);
      expect(uploading.isUploading, isTrue);
      expect(uploading.error, isNull);
    });

    test('drive import progress tracking', () {
      const state = KnowledgeState();
      final importing = state.copyWith(
        isImportingDrive: true,
        driveImportTotal: 3,
        driveImportDone: 0,
      );
      expect(importing.isImportingDrive, isTrue);
      expect(importing.driveImportTotal, 3);
      expect(importing.driveImportDone, 0);

      final progress = importing.copyWith(driveImportDone: 1);
      expect(progress.driveImportDone, 1);
      expect(progress.driveImportTotal, 3);

      final done = progress.copyWith(
        isImportingDrive: false,
        driveImportDone: 3,
      );
      expect(done.isImportingDrive, isFalse);
      expect(done.driveImportDone, 3);
    });

    test('error state pattern: not loading with error message', () {
      const loading = KnowledgeState(isLoading: true);
      final errored = loading.copyWith(
        isLoading: false,
        error: 'No internet connection.',
      );
      expect(errored.isLoading, isFalse);
      expect(errored.error, 'No internet connection.');
      expect(errored.activeKb, isNull);
    });

    test('success state pattern: not loading with KB list', () {
      const loading = KnowledgeState(isLoading: true);
      final kbs = [
        KnowledgeBaseModel.fromJson(const {
          'id': 'kb_1',
          'name': 'Research Notes',
          'wallet': 'w1',
          'privacy': 'private',
        }),
      ];
      final success = loading.copyWith(isLoading: false, knowledgeBases: kbs);
      expect(success.isLoading, isFalse);
      expect(success.error, isNull);
      expect(success.knowledgeBases, hasLength(1));
      expect(success.knowledgeBases.first.name, 'Research Notes');
    });

    test(
      'upload complete pattern: isUploading false with updated activeKb',
      () {
        final activeKb = KnowledgeBaseModel.fromJson(const {
          'id': 'kb_1',
          'name': 'My KB',
          'wallet': 'w1',
          'items': <dynamic>[],
        });
        final state = KnowledgeState(isUploading: true, activeKb: activeKb);

        final updatedKb = activeKb.copyWith(
          items: [
            KbItemModel.fromJson(const {
              'id': 'item_1',
              'name': 'doc.pdf',
              'status': 'pending',
            }),
          ],
        );
        final done = state.copyWith(isUploading: false, activeKb: updatedKb);
        expect(done.isUploading, isFalse);
        expect(done.activeKb?.items, hasLength(1));
        expect(done.activeKb?.items.first.name, 'doc.pdf');
      },
    );
  });
}
