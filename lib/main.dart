import 'package:flutter/material.dart';
import 'app.dart';
import 'core/store.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initStore();
  await initNotifications();
  await scheduleAll();
  runApp(const App());
}
