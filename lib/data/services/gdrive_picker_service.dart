/// Google Drive Picker — conditional import.
///
/// On web: loads the real JS-interop implementation.
/// On Android/iOS: loads a stub that returns empty results.
export 'gdrive_picker_service_stub.dart'
    if (dart.library.js_interop) 'gdrive_picker_service_web.dart';