// lib/presentation/screens/reports/reports_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hasbni/data/models/exchange_rate_model.dart';
import 'package:hasbni/data/models/financial_summary_model.dart';
import 'package:hasbni/data/models/profile_model.dart';
import 'package:hasbni/presentation/cubits/profile/profile_cubit.dart';
import 'package:hasbni/presentation/cubits/profile/profile_state.dart';
import 'package:hasbni/presentation/cubits/reports/reports_cubit.dart';
import 'package:hasbni/presentation/cubits/reports/reports_state.dart';
import 'package:intl/intl.dart';

// THIS IS NOW A STATELESS WIDGET THAT PROVIDES THE CUBITS
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ReportsCubit()..loadSummary()),
        // Provide the ProfileCubit and immediately load the profile
        BlocProvider(create: (context) => ProfileCubit()..loadProfile()),
      ],
      child: Scaffold(
        appBar: AppBar(title: const Text('الجرد والتقارير')),
        body: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, profileState) {
            // First, handle the profile loading states
            if (profileState.status == ProfileStatus.loading ||
                profileState.status == ProfileStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (profileState.status == ProfileStatus.failure) {
              return Center(
                child: Text(
                  profileState.errorMessage ?? 'فشل تحميل بيانات المستخدم',
                ),
              );
            }

            // Once the profile is loaded, build the main reports view
            return BlocBuilder<ReportsCubit, ReportsState>(
              builder: (context, reportsState) {
                // Pass the loaded profile and the reports state to the actual UI widget
                return ReportsView(
                  profile: profileState.profile,
                  reportsState: reportsState,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// THIS IS NOW THE MAIN UI WIDGET, IT'S STATEFUL TO MANAGE LOCAL UI STATE
class ReportsView extends StatefulWidget {
  final Profile? profile;
  final ReportsState reportsState;

  const ReportsView({
    super.key,
    required this.profile,
    required this.reportsState,
  });

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  bool _subtractWithdrawals = false;
  String _displayCurrency = 'USD';

  // Helper function to convert amounts from USD to the target currency
  double _convertFromUsd(
    double usdAmount,
    String targetCurrency,
    List<ExchangeRate> rates,
  ) {
    if (targetCurrency == 'USD') return usdAmount;
    try {
      final rate = rates
          .firstWhere((r) => r.currencyCode == targetCurrency)
          .rateToUsd;
      return usdAmount * rate;
    } catch (e) {
      return usdAmount; // fallback to USD if rate not found
    }
  }

  // Helper function to show the date range picker
  Future<void> _pickDateRange(BuildContext context) async {
    final cubit = context.read<ReportsCubit>();
    final now = DateTime.now();
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start:
            cubit.state.customStartDate ??
            now.subtract(const Duration(days: 7)),
        end: cubit.state.customEndDate ?? now,
      ),
    );
    if (dateRange != null) {
      cubit.loadSummary(customDateRange: dateRange);
    }
  }

  // Helper function to format and display the current date range
  String _formatDateRange(ReportsState state) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    switch (state.selectedPeriod) {
      case TimePeriod.today:
        startDate = DateTime(now.year, now.month, now.day);
        endDate = now;
        break;
      case TimePeriod.week:
        startDate = now.subtract(const Duration(days: 6));
        endDate = now;
        break;
      case TimePeriod.month:
        startDate = now.subtract(const Duration(days: 29));
        endDate = now;
        break;
      case TimePeriod.year:
        startDate = DateTime(now.year, 1, 1);
        endDate = now;
        break;
      case TimePeriod.custom:
        startDate = state.customStartDate ?? now;
        endDate = state.customEndDate ?? now;
        break;
    }
    final formatter = DateFormat('yyyy-MM-dd', 'ar');
    return '${formatter.format(startDate)}  -  ${formatter.format(endDate)}';
  }

  @override
  Widget build(BuildContext context) {
    final reportsState = widget.reportsState;
    final profile = widget.profile;

    return Column(
      children: [
        _buildTimePeriodSelector(context, reportsState),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            _formatDateRange(reportsState),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey[400]),
          ),
        ),
        _buildCurrencySelector(profile),
        if (reportsState.status == ReportsStatus.loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (reportsState.status == ReportsStatus.failure)
          Expanded(
            child: Center(child: Text(reportsState.errorMessage ?? "Error")),
          )
        else
          Expanded(
            child: _buildSummaryCards(
              context,
              reportsState.summary,
              profile?.exchangeRates ?? [],
            ),
          ),
      ],
    );
  }

  Widget _buildTimePeriodSelector(BuildContext context, ReportsState state) {
    final cubit = context.read<ReportsCubit>();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: SegmentedButton<TimePeriod>(
        style: SegmentedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        segments: const [
          ButtonSegment(
            value: TimePeriod.today,
            label: Text('يوم'),
            icon: Icon(Icons.today),
          ),
          ButtonSegment(
            value: TimePeriod.week,
            label: Text('أسبوع'),
            icon: Icon(Icons.view_week_outlined),
          ),
          ButtonSegment(
            value: TimePeriod.month,
            label: Text('شهر'),
            icon: Icon(Icons.calendar_month_outlined),
          ),
          ButtonSegment(
            value: TimePeriod.year,
            label: Text('سنة'),
            icon: Icon(Icons.calendar_today_outlined),
          ),
          ButtonSegment(
            value: TimePeriod.custom,
            label: Text('مخصص'),
            icon: Icon(Icons.date_range),
          ),
        ],
        selected: {state.selectedPeriod},
        onSelectionChanged: (newSelection) {
          final selected = newSelection.first;
          if (selected == TimePeriod.custom) {
            _pickDateRange(context);
          } else {
            cubit.loadSummary(period: selected);
          }
        },
      ),
    );
  }

  Widget _buildCurrencySelector(Profile? profile) {
    if (profile == null) return const SizedBox.shrink();
    final List<String> currencies = [
      'USD',
      ...profile.exchangeRates.map((r) => r.currencyCode),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: _displayCurrency,
        decoration: const InputDecoration(
          labelText: 'عرض التقرير بعملة',
          border: OutlineInputBorder(),
        ),
        items: currencies
            .toSet()
            .toList()
            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
            .toList(),
        onChanged: (value) {
          if (value != null) setState(() => _displayCurrency = value);
        },
      ),
    );
  }

  Widget _buildSummaryCards(
    BuildContext context,
    FinancialSummary summary,
    List<ExchangeRate> rates,
  ) {
    final totalRevenue = _convertFromUsd(
      summary.totalRevenue,
      _displayCurrency,
      rates,
    );
    final totalProfit = _convertFromUsd(
      summary.totalProfit,
      _displayCurrency,
      rates,
    );
    final totalExpenses = _convertFromUsd(
      summary.totalExpenses,
      _displayCurrency,
      rates,
    );
    final netProfit = totalProfit - totalExpenses;
    final totalWithdrawals = _convertFromUsd(
      summary.totalWithdrawals,
      _displayCurrency,
      rates,
    );
    final finalNetProfit = _subtractWithdrawals
        ? (netProfit - totalWithdrawals)
        : netProfit;
    final inventoryValue = _convertFromUsd(
      summary.inventoryValue,
      _displayCurrency,
      rates,
    );

    return RefreshIndicator(
      onRefresh: () => context.read<ReportsCubit>().loadSummary(
        period: context.read<ReportsCubit>().state.selectedPeriod,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSummaryCard(
              title: 'إجمالي المبيعات',
              value: totalRevenue,
              currency: _displayCurrency,
              icon: Icons.trending_up,
              color: Colors.green,
            ),
            _buildSummaryCard(
              title: 'إجمالي الربح',
              subtitle: '(المبيعات - تكلفة البضاعة)',
              value: totalProfit,
              currency: _displayCurrency,
              icon: Icons.attach_money,
              color: Colors.lightGreen,
            ),
            _buildSummaryCard(
              title: 'المصروفات',
              value: totalExpenses,
              currency: _displayCurrency,
              icon: Icons.trending_down,
              color: Colors.red,
            ),
            const Divider(height: 32),
            _buildSummaryCard(
              title: 'المسحوبات الشخصية',
              value: totalWithdrawals,
              currency: _displayCurrency,
              icon: Icons.person_remove,
              color: Colors.orange,
            ),
            SwitchListTile(
              title: const Text('طرح المسحوبات لحساب صافي الربح المتبقي'),
              value: _subtractWithdrawals,
              onChanged: (bool value) =>
                  setState(() => _subtractWithdrawals = value),
            ),
            const Divider(height: 20),
            _buildSummaryCard(
              title: 'صافي الربح النهائي',
              subtitle: _subtractWithdrawals
                  ? '(إجمالي الربح - المصروفات - المسحوبات)'
                  : '(إجمالي الربح - المصروفات)',
              value: finalNetProfit,
              currency: _displayCurrency,
              icon: Icons.account_balance_wallet,
              color: finalNetProfit >= 0 ? Colors.blueAccent : Colors.redAccent,
              isLarge: true,
            ),
            const Divider(height: 32),
            _buildSummaryCard(
              title: 'قيمة المخزون الحالية',
              value: inventoryValue,
              currency: _displayCurrency,
              icon: Icons.inventory_2,
              color: Colors.purpleAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    String? subtitle,
    required double value,
    required String currency,
    required IconData icon,
    required Color color,
    bool isLarge = false,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isLarge ? 18 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
            ),
            Text(
              '${value.toStringAsFixed(2)} $currency',
              style: TextStyle(
                fontSize: isLarge ? 22 : 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
