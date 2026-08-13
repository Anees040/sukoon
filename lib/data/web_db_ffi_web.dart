import 'package:sqflite/sqflite.dart';
// sqflite_common_ffi_web is a dev-only dependency, imported here solely for
// Chrome testing. This file is compiled only on web (conditional import in
// web_db_ffi.dart), so the Android release never sees it.
// ignore: depend_on_referenced_packages
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Web only: route sqflite through the WASM implementation so the tracker +
/// qaza database work in Chrome during development.
///
/// Uses the *no-web-worker* factory, which runs sqlite3 on the main isolate
/// and only needs `web/sqlite3.wasm` (no compiled shared worker). This avoids
/// the `webdev`-based setup step, which is broken in this environment.
void configureWebDatabaseFactory() {
  databaseFactory = databaseFactoryFfiWebNoWebWorker;
}
