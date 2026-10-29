import 'package:flutter/material.dart';
import '../core/constants.dart';

Future<List<String>?> ask(BuildContext c, String title, List<String> f, [List<String>? init]) {
  final cs = [for (var i = 0; i < f.length; i++) TextEditingController(text: init?[i] ?? '')];
  return showDialog<List<String>>(context: c, builder: (_) => AlertDialog(
    title: Text(title),
    content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [for (var i = 0; i < f.length; i++) TextField(controller: cs[i], decoration: InputDecoration(labelText: f[i]))])),
    actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
      FilledButton(onPressed: () => Navigator.pop(c, cs.map((e) => e.text.trim()).toList()), child: const Text('OK'))]));
}

Future<String> pickReason(BuildContext c) async => await showDialog<String>(context: c, builder: (_) => SimpleDialog(
  title: const Text('Why did I eat?'),
  children: [for (final r in reasons) SimpleDialogOption(onPressed: () => Navigator.pop(c, r), child: Text(r))])) ?? 'Hungry';

