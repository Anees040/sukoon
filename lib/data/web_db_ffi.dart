/// Selects the platform-appropriate sqflite database factory setup.
///
/// On web this installs the FFI/WASM factory so the tracker + qaza database
/// work in `flutter run -d chrome` (sqflite has no default web backend).
/// On Android/mobile this resolves to a no-op — the shipping app uses the
/// standard sqflite plugin and never touches any web-only code.
library;

export 'web_db_ffi_stub.dart'
    if (dart.library.js_interop) 'web_db_ffi_web.dart';
