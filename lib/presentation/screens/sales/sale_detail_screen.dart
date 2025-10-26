// lib/presentation/screens/sales/sale_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hasbni/core/utils/extention_shortcut.dart';
import 'package:hasbni/data/models/sale_detail_model.dart';
import 'package:hasbni/presentation/cubits/profile/profile_cubit.dart';
import 'package:hasbni/presentation/cubits/profile/profile_state.dart';
import 'package:hasbni/presentation/cubits/sale_detail/sale_detail_cubit.dart';
import 'package:hasbni/presentation/cubits/sale_detail/sale_detail_state.dart';
import 'package:hasbni/presentation/cubits/session/session_cubit.dart';
import 'package:hasbni/presentation/screens/sales/point_of_sale_screen.dart';
import 'package:hasbni/presentation/screens/sales/receipt_screen.dart';
import 'package:intl/intl.dart';

class SaleDetailScreen extends StatelessWidget {
  final int saleId;
  const SaleDetailScreen({super.key, required this.saleId});

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;

    // Provide both cubits needed by this screen and for printing
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => SaleDetailCubit(
            saleId: saleId,
            sessionCubit: context.read<SessionCubit>(),
          ),
        ),
        BlocProvider(create: (context) => ProfileCubit()..loadProfile()),
      ],
      child: BlocListener<SaleDetailCubit, SaleDetailState>(
        listener: (context, state) {
          if (state.status == SaleDetailStatus.returnSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage ?? 'تمت العملية بنجاح'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state.status == SaleDetailStatus.returnFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'فشل الإرجاع'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              'تفاصيل الفاتورة #${saleId}',
              style: TextStyle(fontSize: scaleConfig.scaleText(20)),
            ),
            actions: [
              // Use a BlocBuilder to get access to both states for the print button
              BlocBuilder<ProfileCubit, ProfileState>(
                builder: (context, profileState) {
                  return BlocBuilder<SaleDetailCubit, SaleDetailState>(
                    builder: (context, saleState) {
                      final canPrint =
                          profileState.profile != null &&
                          saleState.saleDetail != null;
                      return IconButton(
                        icon: const Icon(Icons.print_outlined),
                        tooltip: 'طباعة الفاتورة',
                        onPressed: canPrint
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ReceiptScreen(
                                      saleDetail: saleState.saleDetail!,
                                      profile: profileState.profile!,
                                    ),
                                  ),
                                );
                              }
                            : null, // Button is disabled if data is not ready
                      );
                    },
                  );
                },
              ),
              Builder(
                builder: (context) {
                  return IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () =>
                        context.read<SaleDetailCubit>().loadSaleDetails(),
                    tooltip: 'تحديث',
                  );
                },
              ),
            ],
          ),
          body: BlocBuilder<SaleDetailCubit, SaleDetailState>(
            builder: (context, state) {
              if (state.status == SaleDetailStatus.loading &&
                  state.saleDetail == null) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.status == SaleDetailStatus.failure) {
                return Center(
                  child: Text(state.errorMessage ?? 'خطأ في تحميل البيانات.'),
                );
              }
              if (state.saleDetail == null) {
                return const Center(
                  child: Text('لا يمكن تحميل تفاصيل الفاتورة.'),
                );
              }

              final sale = state.saleDetail!;
              return Column(
                children: [
                  _buildHeader(context, sale),
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.all(scaleConfig.scale(8)),
                      itemCount: sale.items.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 16, endIndent: 16),
                      itemBuilder: (context, index) {
                        final item = sale.items[index];
                        return _buildItemTile(
                          context,
                          item,
                          state.status,
                          context.read<SaleDetailCubit>(),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, SaleDetail sale) {
    final scaleConfig = context.scaleConfig;
    final currency = sale.currencyCode;

    return Padding(
      padding: EdgeInsets.all(scaleConfig.scale(16)),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(scaleConfig.scale(12)),
        ),
        child: Padding(
          padding: EdgeInsets.all(scaleConfig.scale(16)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الإجمالي: ${sale.totalPrice.toStringAsFixed(2)} $currency',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontSize: scaleConfig.scaleText(24)),
                    ),
                    SizedBox(height: scaleConfig.scale(8)),
                    Text(
                      'تاريخ الإنشاء: ${DateFormat('yyyy-MM-dd – hh:mm a', 'ar').format(sale.createdAt)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: scaleConfig.scaleText(13),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.receipt_long,
                size: scaleConfig.scale(40),
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemTile(
    BuildContext context,
    SaleDetailItem item,
    SaleDetailStatus status,
    SaleDetailCubit cubit,
  ) {
    final scaleConfig = context.scaleConfig;
    final bool canBeReturned = item.returnableQuantity > 0;

    return ListTile(
      title: Text(
        item.productName,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: scaleConfig.scaleText(16),
        ),
      ),
      subtitle: Text(
        'الكمية المباعة: ${item.quantitySold} | المرتجعة: ${item.returnedQuantity}',
        style: TextStyle(fontSize: scaleConfig.scaleText(13)),
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'return') {
            _showReturnDialog(context, item, cubit);
          } else if (value == 'exchange') {
            _showReturnDialog(context, item, cubit, isExchange: true);
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: 'return',
            child: Row(
              children: [
                const Icon(
                  Icons.assignment_return_outlined,
                  color: Colors.orange,
                ),
                SizedBox(width: scaleConfig.scale(8)),
                const Text('إرجاع'),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'exchange',
            child: Row(
              children: [
                const Icon(Icons.swap_horiz, color: Colors.blue),
                SizedBox(width: scaleConfig.scale(8)),
                const Text('استبدال'),
              ],
            ),
          ),
        ],
        enabled: canBeReturned && status != SaleDetailStatus.processingReturn,
        child: Padding(
          padding: EdgeInsets.all(scaleConfig.scale(8)),
          child: Icon(
            Icons.more_vert,
            color: canBeReturned
                ? Theme.of(context).iconTheme.color
                : Colors.grey,
          ),
        ),
      ),
    );
  }

  void _showReturnDialog(
    BuildContext context,
    SaleDetailItem item,
    SaleDetailCubit cubit, {
    bool isExchange = false,
  }) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            isExchange
                ? 'استبدال: ${item.productName}'
                : 'إرجاع: ${item.productName}',
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText:
                    'الكمية المراد ${isExchange ? 'استبدالها' : 'إرجاعها'}',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'الحقل مطلوب';
                final quantity = int.tryParse(value);
                if (quantity == null || quantity <= 0)
                  return 'أدخل رقماً صحيحاً أكبر من صفر';
                if (quantity > item.returnableQuantity)
                  return 'لا يمكن إرجاع أكثر من ${item.returnableQuantity}';
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final quantity = int.parse(controller.text);
                  Navigator.of(dialogContext).pop();
                  if (isExchange) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PointOfSaleScreen(
                          isExchangeMode: true,
                          itemToExchange: item,
                          returnQuantity: quantity,
                          saleDetailCubit: cubit,
                        ),
                      ),
                    );
                  } else {
                    cubit.returnItem(item.saleItemId, quantity);
                  }
                }
              },
              child: Text(isExchange ? 'التالي' : 'تأكيد الإرجاع'),
            ),
          ],
        );
      },
    );
  }
}
