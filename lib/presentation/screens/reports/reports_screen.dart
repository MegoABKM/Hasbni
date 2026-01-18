import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Import
import 'package:hasbni/data/models/exchange_rate_model.dart';
import 'package:hasbni/data/models/financial_summary_model.dart';
import 'package:hasbni/data/models/profile_model.dart';
import 'package:hasbni/presentation/cubits/profile/profile_cubit.dart';
import 'package:hasbni/presentation/cubits/profile/profile_state.dart';
import 'package:hasbni/presentation/cubits/reports/reports_cubit.dart';
import 'package:hasbni/presentation/cubits/reports/reports_state.dart';
import 'package:hasbni/presentation/screens/reports/taps/charts_tab.dart';
import 'package:hasbni/presentation/screens/reports/taps/dairy_tab.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ReportsCubit()..loadSummary()),
        BlocProvider(create: (context) => ProfileCubit()..loadProfile()),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'الجرد والتقارير',
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0,
        ),
        body: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, profileState) {
            if (profileState.status == ProfileStatus.loading ||
                profileState.status == ProfileStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (profileState.status == ProfileStatus.failure) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 60.r, color: Colors.redAccent),
                    SizedBox(height: 16.h),
                    Text(
                      profileState.errorMessage ?? 'فشل تحميل بيانات المستخدم',
                      style: TextStyle(fontSize: 16.sp),
                    ),
                  ],
                ),
              );
            }

            return BlocBuilder<ReportsCubit, ReportsState>(
              builder: (context, reportsState) {
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

class _ReportsViewState extends State<ReportsView> with SingleTickerProviderStateMixin {
  bool _subtractWithdrawals = false;
  late TabController _tabController;
  String _displayCurrency = 'USD';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
      return usdAmount;
    }
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final cubit = context.read<ReportsCubit>();
    final now = DateTime.now();
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: cubit.state.customStartDate ?? now.subtract(const Duration(days: 7)),
        end: cubit.state.customEndDate ?? now,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Theme.of(context).primaryColor,
              surface: Theme.of(context).scaffoldBackgroundColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (dateRange != null) {
      cubit.loadSummary(customDateRange: dateRange);
    }
  }

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
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // 1. Controls
        Container(
          padding: EdgeInsets.only(bottom: 8.h),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: Offset(0, 4.h),
                blurRadius: 4.r,
              )
            ],
          ),
          child: Column(
            children: [
              _buildTimePeriodSelector(context, widget.reportsState),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 4.h),
                child: Text(
                  _formatDateRange(widget.reportsState),
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              _buildCurrencySelector(widget.profile),
            ],
          ),
        ),

        // 2. Tab Bar
        TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: theme.colorScheme.primary,
          indicatorWeight: 3.h,
          labelStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(fontSize: 14.sp),
          tabs: const [
            Tab(text: "نظرة عامة"),
            Tab(text: "اليوميات"),
            Tab(text: "الرسوم"),
          ],
        ),

        // 3. Content
        Expanded(
          child: widget.reportsState.status == ReportsStatus.loading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSummaryCards(
                        context,
                        widget.reportsState.summary,
                        widget.profile?.exchangeRates ?? []),
                    DiaryTab(
                      items: widget.reportsState.diaryEntries,
                      summary: widget.reportsState.summary,
                      displayCurrency: _displayCurrency,
                    ),
                    ChartsTab(
                      diaryItems: widget.reportsState.diaryEntries,
                      displayCurrency: _displayCurrency,
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildTimePeriodSelector(BuildContext context, ReportsState state) {
    final cubit = context.read<ReportsCubit>();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: SegmentedButton<TimePeriod>(
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 8.w)),
          textStyle: MaterialStateProperty.all(TextStyle(fontSize: 12.sp)),
        ),
        segments: const [
          ButtonSegment(value: TimePeriod.today, label: Text('يوم'), icon: Icon(Icons.today)),
          ButtonSegment(value: TimePeriod.week, label: Text('أسبوع'), icon: Icon(Icons.view_week_outlined)),
          ButtonSegment(value: TimePeriod.month, label: Text('شهر'), icon: Icon(Icons.calendar_month_outlined)),
          ButtonSegment(value: TimePeriod.year, label: Text('سنة'), icon: Icon(Icons.calendar_today_outlined)),
          ButtonSegment(value: TimePeriod.custom, label: Text('مخصص'), icon: Icon(Icons.date_range)),
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
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _displayCurrency,
            isExpanded: true,
            icon: Icon(Icons.keyboard_arrow_down, size: 24.r),
            style: TextStyle(fontSize: 14.sp, color: Theme.of(context).textTheme.bodyLarge?.color),
            items: currencies.toSet().toList().map((c) {
              return DropdownMenuItem(
                value: c,
                child: Text('عرض التقرير بـ: $c', style: TextStyle(fontSize: 14.sp)),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) setState(() => _displayCurrency = value);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(
    BuildContext context,
    FinancialSummary summary,
    List<ExchangeRate> rates,
  ) {
    final totalRevenue = _convertFromUsd(summary.totalRevenue, _displayCurrency, rates);
    final totalProfit = _convertFromUsd(summary.totalProfit, _displayCurrency, rates);
    final totalExpenses = _convertFromUsd(summary.totalExpenses, _displayCurrency, rates);
    final netProfit = totalProfit - totalExpenses;
    final totalWithdrawals = _convertFromUsd(summary.totalWithdrawals, _displayCurrency, rates);
    final finalNetProfit = _subtractWithdrawals ? (netProfit - totalWithdrawals) : netProfit;
    final inventoryValue = _convertFromUsd(summary.inventoryValue, _displayCurrency, rates);

    return RefreshIndicator(
      onRefresh: () => context.read<ReportsCubit>().loadSummary(
        period: context.read<ReportsCubit>().state.selectedPeriod,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildSummaryCard(title: 'المبيعات', value: totalRevenue, currency: _displayCurrency, icon: Icons.trending_up, color: Colors.green)),
                SizedBox(width: 12.w),
                Expanded(child: _buildSummaryCard(title: 'المصروفات', value: totalExpenses, currency: _displayCurrency, icon: Icons.trending_down, color: Colors.red)),
              ],
            ),
            SizedBox(height: 12.h),
            _buildSummaryCard(
              title: 'إجمالي الربح (قبل الخصم)',
              subtitle: '(المبيعات - التكلفة)',
              value: totalProfit,
              currency: _displayCurrency,
              icon: Icons.attach_money,
              color: Colors.lightGreen,
              isLarge: true,
            ),
            Divider(height: 32.h),
            _buildSummaryCard(
              title: 'المسحوبات الشخصية',
              value: totalWithdrawals,
              currency: _displayCurrency,
              icon: Icons.person_remove,
              color: Colors.orange,
            ),
            Container(
              margin: EdgeInsets.symmetric(vertical: 12.h),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: SwitchListTile(
                title: Text('خصم المسحوبات من الصافي', style: TextStyle(fontSize: 14.sp)),
                value: _subtractWithdrawals,
                activeColor: Theme.of(context).primaryColor,
                onChanged: (bool value) => setState(() => _subtractWithdrawals = value),
              ),
            ),
            Divider(height: 24.h),
            _buildSummaryCard(
              title: 'صافي الربح النهائي',
              subtitle: _subtractWithdrawals
                  ? '(الربح - المصروفات - المسحوبات)'
                  : '(الربح - المصروفات)',
              value: finalNetProfit,
              currency: _displayCurrency,
              icon: Icons.account_balance_wallet,
              color: finalNetProfit >= 0 ? Colors.blueAccent : Colors.redAccent,
              isLarge: true,
              isHighlight: true,
            ),
            SizedBox(height: 16.h),
            _buildSummaryCard(
              title: 'قيمة المخزون',
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
    bool isHighlight = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isHighlight ? color.withOpacity(0.15) : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: isHighlight ? Border.all(color: color.withOpacity(0.5)) : null,
        boxShadow: [
          if (!isHighlight)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: Offset(0, 4.h),
              blurRadius: 8.r,
            )
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: isLarge ? 32.r : 24.r, color: color),
                if (isLarge)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      currency,
                      style: TextStyle(fontSize: 10.sp, color: color, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              title,
              style: TextStyle(
                fontSize: isLarge ? 16.sp : 14.sp,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                color: Colors.grey[400], // Muted text for title
              ),
            ),
            if (subtitle != null)
              Padding(
                padding: EdgeInsets.only(top: 4.h),
                child: Text(
                  subtitle,
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                ),
              ),
            SizedBox(height: 8.h),
            Text(
              value.toStringAsFixed(2),
              style: TextStyle(
                fontSize: isLarge ? 24.sp : 18.sp,
                fontWeight: FontWeight.bold,
                color: isHighlight ? color : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            if (!isLarge) 
              Text(
                currency,
                style: TextStyle(fontSize: 10.sp, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}