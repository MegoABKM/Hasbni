
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hasbni/presentation/cubits/sales_history/sale_history_cubit.dart';
import 'package:hasbni/presentation/cubits/sales_history/sale_history_state.dart';
import 'package:hasbni/presentation/screens/sales/sale_detail_screen.dart';
import 'package:intl/intl.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});
  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  final _scrollController = ScrollController();
  late SalesHistoryCubit _salesHistoryCubit;

  @override
  void initState() {
    super.initState();
    _salesHistoryCubit = SalesHistoryCubit()..loadSales();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _salesHistoryCubit.close();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _salesHistoryCubit.loadSales();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _salesHistoryCubit,
      child: Scaffold(
        appBar: AppBar(title: const Text('سجل المبيعات')),
        body: BlocBuilder<SalesHistoryCubit, SalesHistoryState>(
          builder: (context, state) {
            if (state.status == SalesHistoryStatus.loading &&
                state.sales.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.sales.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('لا يوجد سجل مبيعات.'),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () =>
                          _salesHistoryCubit.loadSales(isRefresh: true),
                      child: const Text('تحديث'),
                    ),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async =>
                  _salesHistoryCubit.loadSales(isRefresh: true),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: state.sales.length + (state.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= state.sales.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  final sale = state.sales[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.receipt_long),
                      ),
                      title: Text('فاتورة رقم: #${sale.id}'),
                      subtitle: Text(
                        'الإجمالي: ${sale.totalPrice.toStringAsFixed(2)} د.ل\n'
                        'التاريخ: ${DateFormat('yyyy-MM-dd – hh:mm a', 'ar').format(sale.createdAt)}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SaleDetailScreen(saleId: sale.id),
                          ),
                        );
                        _salesHistoryCubit.loadSales(isRefresh: true);
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
