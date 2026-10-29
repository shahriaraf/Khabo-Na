import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

late SharedPreferences prefs;
Map<String, dynamic> data = {};

String key(DateTime d) => d.toIso8601String().substring(0, 10);
String today() => key(DateTime.now());
void save() => prefs.setString('d', jsonEncode(data));
Map dayOf(String k) => data.putIfAbsent(k, () => {'eat': [], 'burn': [], 'water': 0, 'sleep': 0, 'steps': 0, 'treat': false});
Map day() => dayOf(today());
num sum(List l, int i) => l.fold<num>(0, (a, e) => a + (e[i] as num));
Map get cfg => data.putIfAbsent('s', () => {'w': 80.0, 'h': 170.0, 'a': 25, 'goal': 70.0, 'rate': 0.5, 'why': 'I want a healthy body.', 'qs': 23, 'qe': 7});
double bmr() => 10.0 * cfg['w'] + 6.25 * cfg['h'] - 5.0 * cfg['a'] + 5;
double budget() { // Safe goal: resting need x1.2 minus the deficit. Never below 1500 kcal.
  final rate = (cfg['rate'] as num).clamp(0.25, 1.0);
  final b = bmr() * 1.2 - rate * 1100;
  return b < 1500 ? 1500 : b;
}
bool quiet(DateTime t) { final s = cfg['qs'] as int, e = cfg['qe'] as int; return s > e ? (t.hour >= s || t.hour < e) : (t.hour >= s && t.hour < e); }
bool treatReady() {
  final n = DateTime.now(), mon = n.subtract(Duration(days: n.weekday - 1));
  for (var i = 0; i < 7; i++) { if (data[key(mon.add(Duration(days: i)))]?['treat'] == true) return false; }
  return true;
}
int streak() {
  var n = 0, d = DateTime.now();
  while (true) {
    final k = key(d), v = data[k];
    final has = v != null && (v['eat'] as List).isNotEmpty;
    if (has && (v['treat'] == true || sum(v['eat'], 2) <= budget() * 0.05 / 4)) { n++; }
    else if (!(k == today() && !has)) { break; }
    d = d.subtract(const Duration(days: 1));
  }
  return n;
}


Future<void> initStore() async {
  prefs = await SharedPreferences.getInstance();
  data = jsonDecode(prefs.getString('d') ?? '{}') as Map<String, dynamic>;
}

void saveMeal(String name, List entries) {
  ((data['meals'] ??= []) as List).add({'name': name, 'items': [for (final e in entries) [e[0], e[1], e[2]]]});
  save();
}
