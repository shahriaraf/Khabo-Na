import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/store.dart';

class _Box extends StatelessWidget {
  const _Box(this.title, this.child);
  final String title; final Widget child;
  @override
  Widget build(BuildContext c) => Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 12), SizedBox(height: 180, child: child)])));
}

FlTitlesData _titles(String Function(double) f) => FlTitlesData(
  topTitles: const AxisTitles(), rightTitles: const AxisTitles(),
  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) => Text(f(v), style: const TextStyle(fontSize: 11)))));

class WeeklyChart extends StatelessWidget {
  const WeeklyChart({super.key});
  @override
  Widget build(BuildContext c) {
    final days = [for (var i = 6; i >= 0; i--) DateTime.now().subtract(Duration(days: i))];
    final vals = [for (final d in days) (data[key(d)] == null ? 0 : sum(data[key(d)]['eat'], 1)).toDouble()];
    final b = budget();
    return _Box('Calories eaten, last 7 days (orange line = your budget)', BarChart(BarChartData(
      maxY: vals.fold<double>(b, max) * 1.2,
      barGroups: [for (var i = 0; i < 7; i++) BarChartGroupData(x: i, barRods: [BarChartRodData(toY: vals[i], width: 14, color: vals[i] > b ? Colors.red : Colors.green)])],
      extraLinesData: ExtraLinesData(horizontalLines: [HorizontalLine(y: b, color: Colors.orange, strokeWidth: 2)]),
      titlesData: _titles((v) => '${days[v.toInt()].day}'),
      gridData: const FlGridData(show: false), borderData: FlBorderData(show: false))));
  }
}

class WeightChart extends StatelessWidget {
  const WeightChart({super.key});
  @override
  Widget build(BuildContext c) {
    final wt = ((data['wt'] ?? []) as List);
    final last = wt.length > 12 ? wt.sublist(wt.length - 12) : wt;
    if (last.length < 2) return const _Box('Weight (kg)', Center(child: Text('Add at least 2 weight checks to see your line.')));
    return _Box('Weight (kg)', LineChart(LineChartData(
      lineBarsData: [LineChartBarData(spots: [for (var i = 0; i < last.length; i++) FlSpot(i.toDouble(), (last[i][1] as num).toDouble())], color: Colors.green, barWidth: 3)],
      titlesData: _titles((v) => v == v.roundToDouble() ? '${(last[v.toInt()][0] as String).substring(5)}' : ''),
      gridData: const FlGridData(show: false), borderData: FlBorderData(show: false))));
  }
}
