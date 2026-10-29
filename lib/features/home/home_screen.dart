import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants.dart';
import '../../core/store.dart';
import '../../services/food_ai_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/dialogs.dart';
import '../craving/craving_screen.dart';
import '../meals/meals_screen.dart';
import '../progress/charts.dart';

class HomeScreen extends StatefulWidget { const HomeScreen({super.key}); @override State<HomeScreen> createState() => _HomeScreenState(); }

class _HomeScreenState extends State<HomeScreen> {
  int tab = 0;
  void done() { save(); scheduleAll(); setState(() {}); }
  Future<void> msg(String s) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  Future<void> addFood() async {
    final c = context;
    final r = await ask(c, 'Add food', ['Food name', 'Calories (kcal)', 'Sugar (grams)']);
    final k = int.tryParse(r?[1] ?? '');
    if (r == null || k == null) return;
    final why = await pickReason(c);
    day()['eat'].add([r[0], k, int.tryParse(r[2]) ?? 0, why]); done();
  }

  Future<void> addBurn() async {
    final c = context;
    final r = await ask(c, 'Workout from Lose Weight app', ['Name', 'Calories burned']);
    final k = int.tryParse(r?[1] ?? '');
    if (r == null || k == null) return;
    day()['burn'].add([r[0], k]); done();
  }

  Future<void> addActivity() async {
    final c = context;
    final r = await ask(c, met.keys.join(', '), ['Activity (from list)', 'Minutes']);
    final k = met.keys.firstWhere((e) => e.toLowerCase() == (r?[0] ?? '').toLowerCase(), orElse: () => '');
    final mins = int.tryParse(r?[1] ?? '');
    if (r == null || k.isEmpty || mins == null) { msg('Use an activity name from the list.'); return; }
    day()['burn'].add([k, (met[k]! * cfg['w'] * mins / 60).round()]); done();
  }

  Future<void> scan() async {
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.camera, maxWidth: 1280);
      if (x == null) return;
      msg('Reading your meal...');
      final items = await FoodAi.analyze(File(x.path));
      await review(items);
    } catch (e) { msg('Scan failed. Please add the food by hand.'); }
  }

  Future<void> review(List items) async {
    final c = context;
    final ns = [for (final i in items) TextEditingController(text: '${i['name']}')];
    final gs = [for (final i in items) TextEditingController(text: '${(i['grams'] as num).round()}')];
    num kc(int i) => (num.tryParse(gs[i].text) ?? 0) * (items[i]['kcal_per_100g'] as num) / 100;
    final ok = await showDialog<bool>(context: c, builder: (_) => StatefulBuilder(builder: (d, ss) {
      final tot = List.generate(items.length, kc).fold<num>(0, (a, b) => a + b);
      return AlertDialog(
        title: const Text('Check each item'),
        content: SingleChildScrollView(child: Column(children: [
          const Text('Photos are only estimates. Weigh your food and fix the grams for the best accuracy.'),
          for (var i = 0; i < items.length; i++) Row(children: [
            Expanded(flex: 3, child: TextField(controller: ns[i])), const SizedBox(width: 8),
            Expanded(flex: 2, child: TextField(controller: gs[i], keyboardType: TextInputType.number, onChanged: (_) => ss(() {}), decoration: const InputDecoration(suffixText: 'g'))),
            SizedBox(width: 52, child: Text(' ${kc(i).round()}'))]),
          const SizedBox(height: 8), Text('Total: ${tot.round()} kcal'),
        ])),
        actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Save meal'))]);
    }));
    if (ok != true || !mounted) return;
    final why = await pickReason(c);
    final saved = [];
    for (var i = 0; i < items.length; i++) {
      final g = num.tryParse(gs[i].text) ?? 0;
      final e = [ns[i].text, kc(i).round(), (g * (items[i]['sugar_per_100g'] as num) / 100).round(), why];
      day()['eat'].add(e);
      saved.add(e);
    }
    done();
    if (!mounted) return;
    final n = await ask(context, 'Save as My Meal?', ['Meal name (leave empty to skip)']);
    if (n != null && n[0].isNotEmpty) saveMeal(n[0], saved);
  }

  Future<void> addRem([int? i]) async {
    final c = context;
    final list = (data['rem'] ??= []) as List;
    final r = await ask(c, 'Reminder', ['Messages (separate with |)', 'Every how many minutes?'], i == null ? null : [list[i]['text'], '${list[i]['min']}']);
    final m = int.tryParse(r?[1] ?? '');
    if (r == null || r[0].isEmpty || m == null || m < 1) return;
    final item = {'text': r[0], 'min': m, 'on': true};
    i == null ? list.add(item) : list[i] = item;
    done();
  }

  Future<void> settings() async {
    final c = context;
    final r = await ask(c, 'My details', ['Weight kg', 'Height cm', 'Age', 'Goal weight kg', 'Loss per week kg (max 1)', 'My reason for losing weight', 'Quiet from hour (0-23)', 'Quiet until hour (0-23)'],
      ['${cfg['w']}', '${cfg['h']}', '${cfg['a']}', '${cfg['goal']}', '${cfg['rate']}', cfg['why'], '${cfg['qs']}', '${cfg['qe']}']);
    if (r == null) return;
    cfg['w'] = double.tryParse(r[0]) ?? cfg['w']; cfg['h'] = double.tryParse(r[1]) ?? cfg['h']; cfg['a'] = int.tryParse(r[2]) ?? cfg['a'];
    cfg['goal'] = double.tryParse(r[3]) ?? cfg['goal']; cfg['rate'] = double.tryParse(r[4]) ?? cfg['rate']; cfg['why'] = r[5];
    cfg['qs'] = int.tryParse(r[6]) ?? cfg['qs']; cfg['qe'] = int.tryParse(r[7]) ?? cfg['qe'];
    done();
  }

  Future<void> counter(String k, String label) async {
    final c = context;
    final r = await ask(c, label, ['Number']);
    final n = num.tryParse(r?[0] ?? '');
    if (n != null) { day()[k] = n; done(); }
  }

  Widget todayPage() {
    final d = day(), eaten = sum(d['eat'], 1), burned = sum(d['burn'], 1), sugar = sum(d['eat'], 2);
    final b = budget(), net = (eaten - bmr() - burned).round(), left = (b - eaten + burned).round();
    return ListView(padding: const EdgeInsets.all(12), children: [
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Daily food budget: ${b.round()} kcal'), Text('Eaten: $eaten kcal'), Text('Exercise burned: $burned kcal'),
        Text('Resting burn (BMR): ${bmr().round()} kcal'), const Divider(),
        Text('Left today: $left kcal', style: Theme.of(context).textTheme.titleLarge),
        Text('Day result vs resting burn: ${net > 0 ? '+' : ''}$net kcal'),
        if (eaten > 0 && eaten < 1500) const Text('You ate under 1,500 kcal. Please do not starve. It leads to bingeing.', style: TextStyle(color: Colors.red)),
      ]))),
      Wrap(spacing: 8, children: [
        FilledButton.icon(onPressed: scan, icon: const Icon(Icons.camera_alt), label: const Text('Scan meal')),
        OutlinedButton(onPressed: addFood, child: const Text('Add food')),
        OutlinedButton(onPressed: addBurn, child: const Text('Add workout')),
        OutlinedButton(onPressed: addActivity, child: const Text('Add activity')),
        OutlinedButton(onPressed: settings, child: const Text('My details')),
        OutlinedButton(onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const MealsScreen())); done(); }, child: const Text('My meals')),
      ]),
      Card(child: ListTile(
        title: Text('Sugar today: ${sugar.round()} g'),
        subtitle: Text('Best: under ${(b * 0.05 / 4).round()} g (5%). Limit: ${(b * 0.10 / 4).round()} g (10%) - WHO. Streak: ${streak()} days'))),
      Card(child: ListTile(
        title: Text(d['treat'] == true ? 'Weekly treat used today' : (treatReady() ? 'Weekly treat available' : 'Weekly treat already used')),
        trailing: treatReady() ? TextButton(onPressed: () { d['treat'] = true; done(); }, child: const Text('Use it')) : null)),
      Wrap(spacing: 8, children: [
        ActionChip(label: Text('Water: ${d['water']} glasses'), onPressed: () => counter('water', 'Glasses of water today')),
        ActionChip(label: Text('Sleep: ${d['sleep']} h'), onPressed: () => counter('sleep', 'Hours slept')),
        ActionChip(label: Text('Steps: ${d['steps']}'), onPressed: () => counter('steps', 'Steps today')),
      ]),
      for (final e in d['eat']) ListTile(dense: true, leading: const Icon(Icons.restaurant), title: Text('${e[0]}'), subtitle: Text('${e[3]} | sugar ${e[2]} g'), trailing: Text('${e[1]} kcal')),
      for (final e in d['burn']) ListTile(dense: true, leading: const Icon(Icons.fitness_center), title: Text('${e[0]}'), trailing: Text('-${e[1]} kcal')),
    ]);
  }

  Widget remPage() {
    final list = (data['rem'] ??= []) as List;
    return ListView(children: [
      for (var i = 0; i < list.length; i++) ListTile(
        title: Text(list[i]['text']), subtitle: Text('Every ${list[i]['min']} minutes'), onTap: () => addRem(i),
        leading: Switch(value: list[i]['on'] == true, onChanged: (v) { list[i]['on'] = v; done(); }),
        trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () { list.removeAt(i); done(); })),
      const Padding(padding: EdgeInsets.all(20), child: Text('Tap + to add. Use | between messages to rotate them. Reminders work when the app is closed. Open the app once a day to refill them. No reminders during quiet hours.')),
    ]);
  }

  Future<void> weight() async {
    final c = context;
    final r = await ask(c, 'Weekly check', ['Weight kg', 'Waist cm']);
    final w = double.tryParse(r?[0] ?? '');
    if (w == null) return;
    ((data['wt'] ??= []) as List).add([today(), w, double.tryParse(r![1]) ?? 0]);
    cfg['w'] = w; done();
  }

  Widget progressPage() {
    final wt = (data['wt'] ??= []) as List;
    double avg(int from, int to) {
      final l = wt.where((e) { final a = DateTime.now().difference(DateTime.parse(e[0])).inDays; return a >= from && a < to; }).map((e) => e[1] as num).toList();
      return l.isEmpty ? 0 : l.fold<num>(0, (a, b) => a + b) / l.length;
    }
    final thisW = avg(0, 7), lastW = avg(7, 14);
    final counts = {for (final r in reasons) r: 0};
    for (var i = 0; i < 14; i++) {
      final v = data[key(DateTime.now().subtract(Duration(days: i)))];
      if (v != null) { for (final e in v['eat']) { counts[e[3]] = (counts[e[3]] ?? 0) + 1; } }
    }
    return ListView(padding: const EdgeInsets.all(12), children: [
      const WeeklyChart(), const WeightChart(),
      Card(child: ListTile(title: Text('Weight this week (average): ${thisW == 0 ? '-' : thisW.toStringAsFixed(1)} kg'),
        subtitle: Text('Last week: ${lastW == 0 ? '-' : lastW.toStringAsFixed(1)} kg. Goal: ${cfg['goal']} kg.${wt.isNotEmpty ? ' Last waist: ${wt.last[2]} cm.' : ''}'),
        trailing: FilledButton(onPressed: weight, child: const Text('Add')))),
      const Padding(padding: EdgeInsets.all(8), child: Text('Why I ate (last 14 days)', style: TextStyle(fontWeight: FontWeight.bold))),
      for (final e in counts.entries) ListTile(dense: true, title: Text(e.key), trailing: Text('${e.value} times')),
      const Padding(padding: EdgeInsets.all(8), child: Text('Look at the biggest number. If it is Pressure, Stress or Boredom, that is the problem to fix, not hunger.')),
    ]);
  }

  Widget helpPage() {
    final mine = (data['rep'] ??= []) as List;
    return ListView(padding: const EdgeInsets.all(12), children: [
      const Text('Replies for the food trap', style: TextStyle(fontWeight: FontWeight.bold)),
      for (final r in [...defaultReplies, ...mine]) ListTile(dense: true, leading: const Icon(Icons.chat_bubble_outline), title: Text('$r')),
      TextButton(onPressed: () async {
        final c = context;
        final r = await ask(c, 'My reply', ['Reply']);
        if (r != null && r[0].isNotEmpty) { mine.add(r[0]); done(); }
      }, child: const Text('Add my own reply')),
      const Divider(),
      const Text('Please remember: calorie numbers are estimates, not absolute truth. A safe loss is about 0.5-1 kg a week. If you often eat very large amounts and feel out of control, please talk to a doctor or dietitian. This is common and treatable.'),
    ]);
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Khabo Na')),
    body: [todayPage, remPage, progressPage, helpPage][tab](),
    floatingActionButton: tab == 1 ? FloatingActionButton(onPressed: addRem, child: const Icon(Icons.add))
      : tab == 0 ? FloatingActionButton.extended(backgroundColor: Colors.red.shade100, onPressed: () => Navigator.push(c, MaterialPageRoute(builder: (_) => const CravingScreen())), icon: const Icon(Icons.pan_tool), label: const Text('Craving!')) : null,
    bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (i) => setState(() => tab = i), destinations: const [
      NavigationDestination(icon: Icon(Icons.today), label: 'Today'), NavigationDestination(icon: Icon(Icons.notifications), label: 'Reminders'),
      NavigationDestination(icon: Icon(Icons.show_chart), label: 'Progress'), NavigationDestination(icon: Icon(Icons.help_outline), label: 'Help')]));
}