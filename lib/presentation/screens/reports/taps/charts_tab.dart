import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hasbni/core/services/currency_converter_service.dart';
import 'package:hasbni/data/models/dairy_item_model.dart';
import 'package:hasbni/presentation/cubits/profile/profile_cubit.dart';
import 'package:intl/intl.dart';

class ChartsTab extends StatelessWidget {
  final List<DiaryItem> diaryItems;
  final String displayCurrency;

  const ChartsTab({
    super.key,
    required this.diaryItems,
    required this.displayCurrency,
  });

  @override
  Widget build(BuildContext context) {
    if (diaryItems.isEmpty) {
      return const Center(child: Text("لا توجد بيانات كافية للرسم البياني"));
    }

    final data = _processData(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("المبيعات والمصروفات (يومي)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: _buildBarChart(context, data),
          ),
          const SizedBox(height: 32),
          const Text("اتجاه الأداء",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: _buildLineChart(context, data),
          ),
        ],
      ),
    );
  }

  // --- Chart Building Logic ---

  Widget _buildBarChart(BuildContext context, List<_ChartPoint> data) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxY(data) * 1.2,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            // --- FIX IS HERE: Changed tooltipBgColor to getTooltipColor ---
            getTooltipColor: (_) => Colors.blueGrey, 
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String label = rodIndex == 0 ? 'مبيعات' : 'مصروفات';
              return BarTooltipItem(
                '$label\n${rod.toY.toStringAsFixed(1)}',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < data.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('MM-dd').format(data[value.toInt()].date),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data.asMap().entries.map((entry) {
          final index = entry.key;
          final point = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: point.revenue,
                color: Colors.greenAccent,
                width: 12,
                borderRadius: BorderRadius.circular(4),
              ),
              BarChartRodData(
                toY: point.expense,
                color: Colors.redAccent,
                width: 12,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLineChart(BuildContext context, List<_ChartPoint> data) {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.withOpacity(0.2))),
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value.revenue - e.value.expense);
            }).toList(),
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  double _getMaxY(List<_ChartPoint> data) {
    double max = 0;
    for (var p in data) {
      if (p.revenue > max) max = p.revenue;
      if (p.expense > max) max = p.expense;
    }
    return max == 0 ? 100 : max;
  }

  List<_ChartPoint> _processData(BuildContext context) {
    final profile = context.read<ProfileCubit>().state.profile;
    final converter = CurrencyConverterService(profile);

    final Map<String, _ChartPoint> grouped = {};
    
    final sortedItems = List<DiaryItem>.from(diaryItems)
      ..sort((a, b) => a.date.compareTo(b.date));

    for (var item in sortedItems) {
      final key = DateFormat('yyyy-MM-dd').format(item.date);
      final value = converter.convert(item.amount, displayCurrency);

      if (!grouped.containsKey(key)) {
        grouped[key] = _ChartPoint(item.date, 0, 0);
      }

      if (item.type == DiaryType.sale) {
        grouped[key]!.revenue += value;
      } else if (item.type == DiaryType.expense || item.type == DiaryType.withdrawal) {
        grouped[key]!.expense += value;
      }
    }

    return grouped.values.toList();
  }
}

class _ChartPoint {
  final DateTime date;
  double revenue;
  double expense;
  _ChartPoint(this.date, this.revenue, this.expense);
}