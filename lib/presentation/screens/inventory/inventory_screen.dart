import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Import ScreenUtil
import 'package:hasbni/core/services/currency_converter_service.dart';
import 'package:hasbni/data/models/product_model.dart';
import 'package:hasbni/presentation/cubits/inventory/inventory_cubit.dart';
import 'package:hasbni/presentation/cubits/inventory/inventory_state.dart';
import 'package:hasbni/presentation/cubits/profile/profile_cubit.dart';
import 'package:hasbni/presentation/screens/inventory/add_edit_product_screen.dart';
import 'package:intl/intl.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _scrollController = ScrollController();
  Timer? _debounce;

  String _selectedDisplayCurrency = 'USD';

  @override
  void initState() {
    super.initState();
    // Load initial data using the global cubit
    context.read<InventoryCubit>().loadProducts(isRefresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300.h) {
      // Responsive threshold
      context.read<InventoryCubit>().loadProducts();
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<InventoryCubit>().searchProducts(query);
    });
  }

  Future<void> _navigateAndRefresh(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    // Refresh global cubit when returning
    if (mounted) {
      context.read<InventoryCubit>().refresh();
    }
  }

  void _deleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (confirmCtx) => AlertDialog(
        title: Text('تأكيد الحذف', style: TextStyle(fontSize: 18.sp)),
        content: Text(
          'هل أنت متأكد من رغبتك في حذف "${product.name}"؟',
          style: TextStyle(fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(confirmCtx).pop(),
            child: Text('إلغاء', style: TextStyle(fontSize: 14.sp)),
          ),
          TextButton(
            onPressed: () {
              // FIX: Use localId!
              context.read<InventoryCubit>().deleteProduct(product.localId!);
              Navigator.of(confirmCtx).pop();
            },
            child: Text(
              'حذف',
              style: TextStyle(color: Colors.red, fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Get Profile to build currency list
    final profile = context.watch<ProfileCubit>().state.profile;
    final List<String> currencies = ['USD'];
    if (profile != null) {
      for (var rate in profile.exchangeRates) {
        if (rate.rateToUsd > 0) {
          currencies.add(rate.currencyCode);
        }
      }
    }

    // Ensure selected currency still exists
    if (!currencies.contains(_selectedDisplayCurrency)) {
      _selectedDisplayCurrency = 'USD';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('المخزن', style: TextStyle(fontSize: 20.sp)),
        actions: [
          // 2. Dropdown to select currency
          DropdownButton<String>(
            value: _selectedDisplayCurrency,
            dropdownColor: Theme.of(context).cardColor,
            underline: const SizedBox(),
            icon: Icon(Icons.monetization_on_outlined, size: 24.r),
            style: TextStyle(
                fontSize: 14.sp,
                color: Theme.of(context).textTheme.bodyLarge?.color),
            items: currencies.map((c) {
              return DropdownMenuItem(value: c, child: Text(c));
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedDisplayCurrency = val);
              }
            },
          ),
          SizedBox(width: 8.w),
          IconButton(
            icon: Icon(Icons.add, size: 24.r),
            onPressed: () => _navigateAndRefresh(const AddEditProductScreen()),
          ),
        ],
      ),
      body: BlocBuilder<InventoryCubit, InventoryState>(
        builder: (context, state) {
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                child: TextField(
                  onChanged: _onSearchChanged,
                  style: TextStyle(fontSize: 14.sp),
                  decoration: InputDecoration(
                    hintText: 'ابحث...',
                    hintStyle: TextStyle(fontSize: 14.sp),
                    prefixIcon: Icon(Icons.search, size: 24.r),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
                  ),
                ),
              ),
              _buildSortOptions(context, state),
              Expanded(child: _buildBody(context, state)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, InventoryState state) {
    if (state.status == InventoryStatus.loading && state.products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == InventoryStatus.failure) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              state.errorMessage ?? 'حدث خطأ',
              style: TextStyle(fontSize: 16.sp),
            ),
            SizedBox(height: 10.h),
            ElevatedButton(
              onPressed: () => context.read<InventoryCubit>().refresh(),
              child: Text('إعادة المحاولة', style: TextStyle(fontSize: 14.sp)),
            ),
          ],
        ),
      );
    }
    if (state.products.isEmpty) {
      return Center(
        child: Text(
          'لا توجد منتجات.',
          style: TextStyle(fontSize: 16.sp, color: Colors.grey),
        ),
      );
    }

    return _buildDataTable(context, state);
  }

  Widget _buildDataTable(BuildContext context, InventoryState state) {
    // 3. Init Converter
    final profile = context.read<ProfileCubit>().state.profile;
    final converter = CurrencyConverterService(profile);

    return RefreshIndicator(
      onRefresh: () => context.read<InventoryCubit>().refresh(),
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            showCheckboxColumn: false,
            columnSpacing: 20.w, // Responsive spacing
            headingRowHeight: 56.h, // Responsive height
            dataRowMinHeight: 48.h, // Responsive height
            dataRowMaxHeight: 64.h, // Allow growth for text wrapping
            columns: [
              DataColumn(
                  label: Text('الصنف',
                      style: TextStyle(
                          fontSize: 14.sp, fontWeight: FontWeight.bold))),
              DataColumn(
                  label: Text('الكمية',
                      style: TextStyle(
                          fontSize: 14.sp, fontWeight: FontWeight.bold)),
                  numeric: true),
              // 4. Dynamic Header
              DataColumn(
                label: Text('سعر البيع ($_selectedDisplayCurrency)',
                    style: TextStyle(
                        fontSize: 14.sp, fontWeight: FontWeight.bold)),
                numeric: true,
              ),
              DataColumn(
                  label: Text('إجراءات',
                      style: TextStyle(
                          fontSize: 14.sp, fontWeight: FontWeight.bold))),
            ],
            rows: [
              ...state.products.map((product) {
                // 5. Convert Price on the fly
                final displayPrice = converter.convert(
                  product.sellingPrice,
                  _selectedDisplayCurrency,
                );

                return DataRow(
                  onSelectChanged: (selected) {
                    if (selected ?? false) _showProductDetailsDialog(product);
                  },
                  cells: [
                    DataCell(ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 120.w),
                      child: Text(
                        product.name,
                        style: TextStyle(fontSize: 13.sp),
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
                    DataCell(Text(product.quantity.toString(),
                        style: TextStyle(fontSize: 13.sp))),
                    DataCell(
                      Text(displayPrice.toStringAsFixed(2),
                          style: TextStyle(fontSize: 13.sp)),
                    ),
                    DataCell(_buildActionButtons(product)),
                  ],
                );
              }).toList(),
              if (state.status == InventoryStatus.loadingMore)
                DataRow(
                  cells: [
                    const DataCell(Center(child: CircularProgressIndicator())),
                    const DataCell(Text('')),
                    const DataCell(Text('')),
                    const DataCell(Text('')),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProductDetailsDialog(Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(product.name, style: TextStyle(fontSize: 18.sp)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الباركود: ${product.barcode ?? 'لا يوجد'}',
                style: TextStyle(fontSize: 14.sp)),
            Divider(height: 16.h),
            Text('الكمية المتاحة: ${product.quantity}',
                style: TextStyle(fontSize: 14.sp)),
            Divider(height: 16.h),
            Text('سعر التكلفة: \$${product.costPrice.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 14.sp)),
            Text('سعر البيع: \$${product.sellingPrice.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 14.sp)),
            Divider(height: 16.h),
            Text(
              'تاريخ الإضافة: ${DateFormat('yyyy-MM-dd', 'ar').format(product.createdAt)}',
              style: TextStyle(fontSize: 13.sp, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          _buildActionButtons(product, fromDialog: true),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('إغلاق', style: TextStyle(fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Product product, {bool fromDialog = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          icon: Icon(
            Icons.edit,
            size: 20.r,
            color: fromDialog
                ? Theme.of(context).colorScheme.secondary
                : Colors.blueAccent,
          ),
          tooltip: 'تعديل',
          onPressed: () {
            if (fromDialog) Navigator.of(context).pop();
            _navigateAndRefresh(AddEditProductScreen(product: product));
          },
        ),
        IconButton(
          icon: Icon(
            Icons.delete,
            size: 20.r,
            color: fromDialog
                ? Theme.of(context).colorScheme.error
                : Colors.redAccent,
          ),
          tooltip: 'حذف',
          onPressed: () {
            if (fromDialog) Navigator.of(context).pop();
            _deleteProduct(product);
          },
        ),
      ],
    );
  }

  Widget _buildSortOptions(BuildContext context, InventoryState state) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Wrap(
        spacing: 8.0.w,
        children: [
          _buildSortChip(context, state, SortBy.name, 'الاسم'),
          _buildSortChip(context, state, SortBy.quantity, 'الكمية'),
          _buildSortChip(context, state, SortBy.sellingPrice, 'السعر'),
          _buildSortChip(context, state, SortBy.createdAt, 'الأحدث'),
        ],
      ),
    );
  }

  Widget _buildSortChip(
    BuildContext context,
    InventoryState state,
    SortBy sortBy,
    String label,
  ) {
    final bool isSelected = state.sortBy == sortBy;
    return ActionChip(
      avatar: isSelected
          ? Icon(
              state.ascending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16.r,
            )
          : null,
      label: Text(label, style: TextStyle(fontSize: 12.sp)),
      onPressed: () =>
          context.read<InventoryCubit>().changeSort(sortBy: sortBy),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0.r),
        side: BorderSide(
          color:
              isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
        ),
      ),
      backgroundColor: isSelected
          ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
          : Colors.transparent,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0),
    );
  }
}
