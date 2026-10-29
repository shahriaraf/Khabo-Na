import 'package:flutter/material.dart';
import '../../core/store.dart';
import '../../services/notification_service.dart';
import '../../widgets/dialogs.dart';

class MealsScreen extends StatefulWidget {
  const MealsScreen({super.key});
  @override
  State<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends State<MealsScreen> {
  List get meals => (data['meals'] ??= []) as List;

  Future<void> log(Map m) async {
    final r = await ask(context, 'Portion (1 = same as saved)', ['Portion'], ['1']);
    final p = double.tryParse(r?[0] ?? '');
    if (p == null || p <= 0 || !mounted) return;
    final why = await pickReason(context);
    for (final i in m['items']) {
      day()['eat'].add([i[0], ((i[1] as num) * p).round(), ((i[2] as num) * p).round(), why]);
    }
    save();
    scheduleAll();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Meal added to today.')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My meals')),
    body: meals.isEmpty
      ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No saved meals yet. After you scan a meal, choose a name to save it. Weigh it once, reuse it forever.')))
      : ListView(children: [
          for (var i = 0; i < meals.length; i++) ListTile(
            title: Text(meals[i]['name']), subtitle: Text('${sum(meals[i]['items'], 1)} kcal | sugar ${sum(meals[i]['items'], 2)} g'),
            onTap: () => log(meals[i]),
            trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () { meals.removeAt(i); save(); setState(() {}); })),
        ]));
}
