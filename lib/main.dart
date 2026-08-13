import 'package:flutter/material.dart';

import 'package:sukoon/app.dart';
import 'package:sukoon/core/prefs.dart';
import 'package:sukoon/data/web_db_ffi.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureWebDatabaseFactory(); // no-op on Android; installs web DB on Chrome
  await Prefs.init();
  runApp(const SukoonApp());
}
