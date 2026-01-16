import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hasbni/core/services/currency_converter_service.dart';
import 'package:hasbni/data/models/dairy_item_model.dart';
import 'package:hasbni/data/models/expense_model.dart';
import 'package:hasbni/data/models/sale_model.dart';
import 'package:hasbni/data/models/withdrawal_model.dart';
import 'package:hasbni/data/models/financial_summary_model.dart';
import 'package:hasbni/presentation/cubits/profile/profile_cubit.dart';
import 'package:hasbni/presentation/screens/sales/sale_detail_screen.dart';
import 'package:intl/intl.dart';

class DiaryTab extends StatelessWidget {
  final List<DiaryItem> items;
  final FinancialSummary summary;
  final String displayCurrency;

  const DiaryTab({
    super.key,
    required this.items,
    required this.summary,
    required this.displayCurrency,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text('لا توجد عمليات في هذه الفترة'),
      );
    }

    return ListView.builder(
      itemCount: items.length + 1, // +1 for the Summary Footer
      itemBuilder: (context, index) {
        // --- FOOTER: TOTALS ---
        if (index == items.length) {
          return _buildTotalsFooter(context);
        }

        // --- LIST ITEMS ---
        final item = items[index];
        return _buildDiaryItem(context, item);
      },
    );
  }

  Widget _buildDiaryItem(BuildContext context, DiaryItem item) {
    final profile = context.read<ProfileCubit>().state.profile;
    final converter = CurrencyConverterService(profile);

    IconData icon;
    Color color;
    String amountText = '';
    String subtitle = '';

    // Convert stored USD amount to Display Currency
    final displayAmount = converter.convert(item.amount, displayCurrency);

    switch (item.type) {
      case DiaryType.sale:
        icon = Icons.receipt_long;
        color = Colors.green;
        final sale = item.originalItem as Sale;
        // Sales store their own currency code, but we want to show it in the selected display currency
        amountText = '+ ${displayAmount.toStringAsFixed(2)} $displayCurrency';
        subtitle = 'العملة الأصلية: ${sale.currencyCode}';
        break;

      case DiaryType.expense:
        icon = Icons.money_off;
        color = Colors.red;
        final expense = item.originalItem as Expense;
        amountText = '- ${displayAmount.toStringAsFixed(2)} $displayCurrency';
        subtitle = 'الفئة: ${expense.categoryId ?? "عام"}'; 
        // Note: You might need to look up category name in a real scenario, 
        // or just store category name in Expense model for UI.
        break;

      case DiaryType.withdrawal:
        icon = Icons.person_remove;
        color = Colors.orange;
        amountText = '- ${displayAmount.toStringAsFixed(2)} $displayCurrency';
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle, style: const TextStyle(fontSize: 12)),
            Text(
              DateFormat('yyyy-MM-dd hh:mm a', 'ar').format(item.date),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        trailing: Text(
          amountText,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        onTap: () {
          if (item.type == DiaryType.sale) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SaleDetailScreen(saleId: (item.originalItem as Sale).id),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildTotalsFooter(BuildContext context) {
    final profile = context.read<ProfileCubit>().state.profile;
    final converter = CurrencyConverterService(profile);

    double convert(double usd) => converter.convert(usd, displayCurrency);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "ملخص الفترة المحدد",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          _buildSummaryRow("المبيعات", convert(summary.totalRevenue), Colors.green),
          _buildSummaryRow("المصروفات", convert(summary.totalExpenses), Colors.red),
          _buildSummaryRow("المسحوبات", convert(summary.totalWithdrawals), Colors.orange),
          const Divider(),
          _buildSummaryRow(
            "صافي الربح", 
            convert(summary.netProfit), 
            summary.netProfit >= 0 ? Colors.blue : Colors.red,
            isBold: true
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, Color color, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            '${value.toStringAsFixed(2)} $displayCurrency',
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: isBold ? 16 : 14),
          ),
        ],
      ),
    );
  }
}