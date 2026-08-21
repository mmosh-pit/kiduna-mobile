import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna_mobile/data/services/gdrive_service.dart';

void main() {
  group('DriveFile', () {
    test('isIngestible returns true for supported MIME types', () {
      const pdf = DriveFile(
        id: '1',
        name: 'doc.pdf',
        mimeType: 'application/pdf',
      );
      const txt = DriveFile(id: '2', name: 'notes.txt', mimeType: 'text/plain');
      const docx = DriveFile(
        id: '3',
        name: 'report.docx',
        mimeType:
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      );
      const gdoc = DriveFile(
        id: '4',
        name: 'Meeting Notes',
        mimeType: 'application/vnd.google-apps.document',
      );

      expect(pdf.isIngestible, isTrue);
      expect(txt.isIngestible, isTrue);
      expect(docx.isIngestible, isTrue);
      expect(gdoc.isIngestible, isTrue);
    });

    test('isIngestible returns false for unsupported MIME types', () {
      const xlsx = DriveFile(
        id: '1',
        name: 'data.xlsx',
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      const png = DriveFile(id: '2', name: 'image.png', mimeType: 'image/png');

      expect(xlsx.isIngestible, isFalse);
      expect(png.isIngestible, isFalse);
    });

    test('isWorkspaceFile detects Google Workspace types', () {
      const gdoc = DriveFile(
        id: '1',
        name: 'Doc',
        mimeType: 'application/vnd.google-apps.document',
      );
      const gsheet = DriveFile(
        id: '2',
        name: 'Sheet',
        mimeType: 'application/vnd.google-apps.spreadsheet',
      );
      const pdf = DriveFile(
        id: '3',
        name: 'doc.pdf',
        mimeType: 'application/pdf',
      );

      expect(gdoc.isWorkspaceFile, isTrue);
      expect(gsheet.isWorkspaceFile, isTrue);
      expect(pdf.isWorkspaceFile, isFalse);
    });

    test('isOversized detects files over 5 MB', () {
      const large = DriveFile(
        id: '1',
        name: 'big.pdf',
        mimeType: 'application/pdf',
        sizeBytes: 6 * 1024 * 1024,
      );
      const small = DriveFile(
        id: '2',
        name: 'small.pdf',
        mimeType: 'application/pdf',
        sizeBytes: 1024,
      );
      const exact = DriveFile(
        id: '3',
        name: 'exact.pdf',
        mimeType: 'application/pdf',
        sizeBytes: 5 * 1024 * 1024,
      );
      const noSize = DriveFile(
        id: '4',
        name: 'unknown.pdf',
        mimeType: 'application/pdf',
      );

      expect(large.isOversized, isTrue);
      expect(small.isOversized, isFalse);
      expect(exact.isOversized, isFalse);
      expect(noSize.isOversized, isFalse);
    });

    test('isOversized skips workspace files', () {
      const largeDocs = DriveFile(
        id: '1',
        name: 'Huge Doc',
        mimeType: 'application/vnd.google-apps.document',
        sizeBytes: 100 * 1024 * 1024,
      );

      expect(largeDocs.isOversized, isFalse);
    });
  });

  group('GdriveService URL parsing', () {
    test('extractFileId from standard file URL', () {
      const url =
          'https://drive.google.com/file/d/1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgVE2upms/view';
      expect(
        GdriveService.extractFileId(url),
        '1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgVE2upms',
      );
    });

    test('extractFileId from Google Docs URL', () {
      const url = 'https://docs.google.com/document/d/1abc-DEF_123/edit';
      expect(GdriveService.extractFileId(url), '1abc-DEF_123');
    });

    test('extractFileId from Sheets URL', () {
      const url = 'https://docs.google.com/spreadsheets/d/1xyz789/edit#gid=0';
      expect(GdriveService.extractFileId(url), '1xyz789');
    });

    test('extractFileId returns null for non-file URLs', () {
      expect(GdriveService.extractFileId('https://google.com'), isNull);
      expect(GdriveService.extractFileId('not a url'), isNull);
      expect(GdriveService.extractFileId(''), isNull);
    });

    test('extractFolderId from folder URL', () {
      const url =
          'https://drive.google.com/drive/folders/1abc-DEF_123?usp=sharing';
      expect(GdriveService.extractFolderId(url), '1abc-DEF_123');
    });

    test('extractFolderId from nested folder URL', () {
      const url = 'https://drive.google.com/drive/u/0/folders/1xyz789';
      expect(GdriveService.extractFolderId(url), '1xyz789');
    });

    test('extractFolderId returns null for non-folder URLs', () {
      expect(GdriveService.extractFolderId('https://google.com'), isNull);
      expect(
        GdriveService.extractFolderId(
          'https://drive.google.com/file/d/abc/view',
        ),
        isNull,
      );
      expect(GdriveService.extractFolderId(''), isNull);
    });

    test('classifyUrl correctly identifies folder URLs', () {
      expect(
        GdriveService.classifyUrl(
          'https://drive.google.com/drive/folders/abc123',
        ),
        DriveUrlType.folder,
      );
    });

    test('classifyUrl correctly identifies file URLs', () {
      expect(
        GdriveService.classifyUrl(
          'https://drive.google.com/file/d/abc123/view',
        ),
        DriveUrlType.file,
      );
      expect(
        GdriveService.classifyUrl(
          'https://docs.google.com/document/d/abc123/edit',
        ),
        DriveUrlType.file,
      );
    });

    test('classifyUrl returns unknown for invalid URLs', () {
      expect(
        GdriveService.classifyUrl('https://google.com'),
        DriveUrlType.unknown,
      );
      expect(GdriveService.classifyUrl('not a url'), DriveUrlType.unknown);
      expect(GdriveService.classifyUrl(''), DriveUrlType.unknown);
    });

    test('classifyUrl prefers folder when URL contains both patterns', () {
      const url = 'https://drive.google.com/drive/folders/abc123?d/xyz';
      expect(GdriveService.classifyUrl(url), DriveUrlType.folder);
    });
  });

  group('kIngestibleMimeTypes', () {
    test('contains all expected types', () {
      expect(kIngestibleMimeTypes, contains('application/pdf'));
      expect(kIngestibleMimeTypes, contains('text/plain'));
      expect(
        kIngestibleMimeTypes,
        contains(
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        ),
      );
      expect(
        kIngestibleMimeTypes,
        contains('application/vnd.google-apps.document'),
      );
    });

    test('has exactly 4 supported types', () {
      expect(kIngestibleMimeTypes, hasLength(4));
    });
  });

  group('kMaxDriveFileSize', () {
    test('is 5 MB', () {
      expect(kMaxDriveFileSize, 5 * 1024 * 1024);
    });
  });
}
