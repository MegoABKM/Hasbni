import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hasbni/core/utils/extention_shortcut.dart';
import 'package:hasbni/data/models/withdrawal_model.dart';
import 'package:hasbni/presentation/cubits/profile/profile_cubit.dart';
import 'package:hasbni/presentation/cubits/withdrawals/withdrawal_cubit.dart';
import 'package:hasbni/presentation/cubits/withdrawals/withdrawal_state.dart';
import 'package:hasbni/presentation/screens/withdrawals/widgets/add_withdrawal_dialog.dart';
import 'package:intl/intl.dart';

class WithdrawalsScreen extends StatelessWidget {
  const WithdrawalsScreen({super.key});

  void _showAddEditDialog(BuildContext context, {Withdrawal? withdrawal}) {
    // --- REMOVED THE BLOCKING CHECK ---
    // We allow the dialog to open even if profile is null.
    // The dialog will simply default to USD if no other currencies are loaded.

    showDialog(
      context: context,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<WithdrawalsCubit>()),
          BlocProvider.value(value: context.read<ProfileCubit>()),
        ],
        child: AddEditWithdrawalDialog(withdrawal: withdrawal),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => WithdrawalsCubit()..loadWithdrawals(),
        ),
        // We still load the profile here to try and get rates in the background
        BlocProvider(create: (context) => ProfileCubit()..loadProfile()),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'المسحوبات الشخصية',
            style: TextStyle(fontSize: scaleConfig.scaleText(20)),
          ),
        ),
        body: BlocBuilder<WithdrawalsCubit, WithdrawalsState>(
          builder: (context, state) {
            if (state.status == WithdrawalsStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.withdrawals.isEmpty) {
              return Center(
                child: Text(
                  'لا توجد مسحوبات مسجلة.',
                  style: TextStyle(fontSize: scaleConfig.scaleText(16)),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () =>
                  context.read<WithdrawalsCubit>().loadWithdrawals(),
              child: ListView.separated(
                padding: EdgeInsets.all(scaleConfig.scale(8)),
                itemCount: state.withdrawals.length,
                separatorBuilder: (context, index) =>
                    SizedBox(height: scaleConfig.scale(8)),
                itemBuilder: (ctx, index) {
                  final withdrawal = state.withdrawals[index];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        scaleConfig.scale(12),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: scaleConfig.scale(16),
                        vertical: scaleConfig.scale(10),
                      ),
                      leading: CircleAvatar(
                        radius: scaleConfig.scale(22),
                        child: Icon(
                          Icons.person_remove_outlined,
                          size: scaleConfig.scale(24),
                        ),
                      ),
                      title: Text(
                        withdrawal.description ?? 'مسحوبات بدون وصف',
                        style: TextStyle(
                          fontSize: scaleConfig.scaleText(16),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        DateFormat.yMMMd(
                          'ar',
                        ).format(withdrawal.withdrawalDate),
                        style: TextStyle(fontSize: scaleConfig.scaleText(13)),
                      ),
                      trailing: Text(
                        '${withdrawal.amountInCurrency.toStringAsFixed(2)} ${withdrawal.currencyCode}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                          fontSize: scaleConfig.scaleText(15),
                        ),
                      ),
                      onTap: () =>
                          _showAddEditDialog(context, withdrawal: withdrawal),
                    ),
                  );
                },
              ),
            );
          },
        ),
        floatingActionButton: Builder(
          builder: (context) => FloatingActionButton(
            onPressed: () => _showAddEditDialog(context),
            tooltip: 'إضافة سحب',
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}