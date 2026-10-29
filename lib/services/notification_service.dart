import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../core/store.dart';

final plugin = FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  tz.initializeTimeZones();
  await plugin.initialize(const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher'), iOS: DarwinInitializationSettings()));
  final a = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  await a?.requestNotificationsPermission();
  await a?.requestExactAlarmsPermission();
}

const nd = NotificationDetails(
  android: AndroidNotificationDetails('coach', 'Coach reminders', importance: Importance.max, priority: Priority.high),
  iOS: DarwinNotificationDetails());

Future<void> sched(int id, String t, String b, tz.TZDateTime at) async {
  try {
    await plugin.zonedSchedule(
      id,
      t,
      b,
      at,
      nd,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  } catch (_) {
    await plugin.zonedSchedule(
      id,
      t,
      b,
      at,
      nd,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}

Future<void> scheduleAll() async {
  await plugin.cancelAll();
  final cap = Platform.isIOS ? 60 : 400;
  var id = 1;
  final now = tz.TZDateTime.now(tz.local);
  for (final r in (data['rem'] as List? ?? [])) {
    if (r['on'] != true) continue;
    final msgs = (r['text'] as String).split('|').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (msgs.isEmpty) continue;
    var sent = 0;
    for (var k = 1; k <= 3000 && id < cap && sent < 150; k++) {
      final at = now.add(Duration(minutes: (r['min'] as int) * k));
      if (at.difference(now).inHours >= 48) break;
      if (quiet(at)) continue;
      await sched(id++, 'Stay strong', msgs[sent % msgs.length], at);
      sent++;
    }
  }
  final d = day();
  final net = (sum(d['eat'], 1) - bmr() - sum(d['burn'], 1)).round();
  var at = tz.TZDateTime(tz.local, now.year, now.month, now.day, 22);
  if (at.isBefore(now)) at = at.add(const Duration(days: 1));
  await sched(99999, 'Day result', 'Ate ${sum(d['eat'], 1)} kcal, exercise ${sum(d['burn'], 1)} kcal. Result: ${net > 0 ? '+' : ''}$net kcal vs resting burn.', at);
}

