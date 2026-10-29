import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/store.dart';

class CravingScreen extends StatefulWidget { const CravingScreen({super.key}); @override State<CravingScreen> createState() => _CravingState(); }
class _CravingState extends State<CravingScreen> {
  int s = 600; late Timer t;
  @override void initState() { super.initState(); t = Timer.periodic(const Duration(seconds: 1), (_) { if (s > 0) setState(() => s--); }); }
  @override void dispose() { t.cancel(); super.dispose(); }
  @override Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Wait 10 minutes')),
    body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 64)),
      const SizedBox(height: 16), Text('My reason:\n${cfg['why']}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 20)),
      const SizedBox(height: 16), const Text('Drink water. Walk around. A craving usually passes in 10-15 minutes.', textAlign: TextAlign.center)]))));
}
