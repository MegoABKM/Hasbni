import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hasbni/core/utils/extention_shortcut.dart';
import 'package:hasbni/core/utils/scale_config.dart';
import 'package:hasbni/data/models/withdrawal_model.dart';
import 'package:hasbni/presentation/cubits/profile/profile_cubit.dart';
import 'package:hasbni/presentation/cubits/withdrawals/withdrawal_cubit.dart';
import 'package:hasbni/presentation/cubits/withdrawals/withdrawal_state.dart';
import 'package:hasbni/presentation/screens/withdrawals/widgets/add_withdrawal_dialog.dart';
import 'package:intl/intl.dart';

class WithdrawalsScreen extends StatefulWidget {
  const WithdrawalsScreen({super.key});

  @override
  State<WithdrawalsScreen> createState() => _WithdrawalsScreenState();
}

class _WithdrawalsScreenState extends State<WithdrawalsScreen> {
  DateTime _selectedMonth = DateTime.now();

  void _showAddEditDialog(BuildContext context, {Withdrawal? withdrawal}) {
    showDialog(
      context: context,
      builder: (dialogContext) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<WithdrawalsCubit>()),
          BlocProvider.value(value: context.read<ProfileCubit>()),
        ],
        child: AddEditWithdrawalDialog(withdrawal: withdrawal),
      ),
    );
  }

  Future<void> _pickMonth(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'اختر الشهر والسنة',
    );
    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => WithdrawalsCubit()..loadWithdrawals()),
        BlocProvider(create: (context) => ProfileCubit()..loadProfile()),
      ],
      // Builder is crucial here to ensure FAB finds the Cubits
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: InkWell(
                onTap: () => _pickMonth(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'المسحوبات: ${DateFormat.yMMM('ar').format(_selectedMonth)}',
                      style: TextStyle(fontSize: scaleConfig.scaleText(18)),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
              centerTitle: true,
            ),
            body: BlocBuilder<WithdrawalsCubit, WithdrawalsState>(
              builder: (context, state) {
                if (state.status == WithdrawalsStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 1. Filter by Month
                final filtered = state.withdrawals.where((w) {
                  return w.withdrawalDate.year == _selectedMonth.year &&
                      w.withdrawalDate.month == _selectedMonth.month;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'لا توجد مسحوبات في ${DateFormat.yMMM('ar').format(_selectedMonth)}.',
                      style: TextStyle(fontSize: scaleConfig.scaleText(16)),
                    ),
                  );
                }

                // 2. Group by Date
                final groupedWithdrawals = <String, List<Withdrawal>>{};
                for (var w in filtered) {
                  final dateKey = DateFormat('yyyy-MM-dd').format(w.withdrawalDate);
                  if (!groupedWithdrawals.containsKey(dateKey)) {
                    groupedWithdrawals[dateKey] = [];
                  }
                  groupedWithdrawals[dateKey]!.add(w);
                }
                final sortedKeys = groupedWithdrawals.keys.toList()
                  ..sort((a, b) => b.compareTo(a));

                return RefreshIndicator(
                  onRefresh: () => context.read<WithdrawalsCubit>().loadWithdrawals(),
                  child: ListView.builder(
                    padding: EdgeInsets.all(scaleConfig.scale(8)),
                    itemCount: sortedKeys.length,
                    itemBuilder: (ctx, index) {
                      final dateKey = sortedKeys[index];
                      final dayWithdrawals = groupedWithdrawals[dateKey]!;
                      final date = DateTime.parse(dateKey);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date Header
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 4.0),
                            child: Text(
                              _formatDateHeader(date),
                              style: TextStyle(
                                fontSize: scaleConfig.scaleText(14),
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          // List Items
                          ...dayWithdrawals.map((withdrawal) {
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(scaleConfig.scale(12)),
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: scaleConfig.scale(16),
                                  vertical: scaleConfig.scale(10),
                                ),
                                leading: CircleAvatar(
                                  radius: scaleConfig.scale(22),
                                  child: Icon(Icons.person_remove_outlined,
                                      size: scaleConfig.scale(24)),
                                ),
                                title: Text(
                                  withdrawal.description?.isNotEmpty == true
                                      ? withdrawal.description!
                                      : 'سحب بدون وصف',
                                  style: TextStyle(
                                    fontSize: scaleConfig.scaleText(16),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  DateFormat('hh:mm a', 'ar')
                                      .format(withdrawal.withdrawalDate),
                                  style: TextStyle(
                                      fontSize: scaleConfig.scaleText(13)),
                                ),
                                trailing: Text(
                                  '${withdrawal.amountInCurrency.toStringAsFixed(2)} ${withdrawal.currencyCode}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                    fontSize: scaleConfig.scaleText(15),
                                  ),
                                ),
                                onTap: () => _showAddEditDialog(context,
                                    withdrawal: withdrawal),
                              ),
                            );
                          }).toList(),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => _showAddEditDialog(context),
              tooltip: 'إضافة سحب',
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) return 'اليوم';
    if (checkDate == yesterday) return 'أمس';
    return DateFormat.yMMMd('ar').format(date);
  }
}