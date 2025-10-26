// lib/presentation/screens/inventory/inventory_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hasbni/data/models/product_model.dart';
import 'package:hasbni/presentation/cubits/inventory/inventory_cubit.dart';
import 'package:hasbni/presentation/cubits/inventory/inventory_state.dart';
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
  late InventoryCubit _inventoryCubit;

  @override
  void initState() {
    super.initState();
    _inventoryCubit = InventoryCubit()..loadProducts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _debounce?.cancel();
    _inventoryCubit.close();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _inventoryCubit.loadProducts();
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _inventoryCubit.searchProducts(query);
    });
  }

  Future<void> _navigateAndRefresh(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            BlocProvider.value(value: _inventoryCubit, child: screen),
      ),
    );
    _inventoryCubit.refresh();
  }

  void _deleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (confirmCtx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من رغبتك في حذف "${product.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(confirmCtx).pop(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              _inventoryCubit.deleteProduct(product.id);
              Navigator.of(confirmCtx).pop();
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _inventoryCubit,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المخزن'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () =>
                  _navigateAndRefresh(const AddEditProductScreen()),
            ),
          ],
        ),
        body: BlocBuilder<InventoryCubit, InventoryState>(
          builder: (context, state) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    onChanged: _onSearchChanged,
                    decoration: const InputDecoration(
                      hintText: 'ابحث...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                _buildSortOptions(context, state),
                Expanded(child: _buildBody(context, state)),
              ],
            );
          },
        ),
      ),
    );
  }

  // Widget _buildCurrencySelector() {
  //   return BlocBuilder<AuthCubit, AuthState>(
  //     builder: (context, authState) {
  //       final profile = authState.profile;
  //       if (profile == null) return const SizedBox.shrink();

  //       final List<String> currencies = [
  //         'USD',
  //         ...profile.exchangeRates.map((r) => r.currencyCode),
  //       ];
  //       if (!currencies.contains(profile.currency)) {
  //         currencies.insert(0, profile.currency);
  //       }

  //       return Padding(
  //         padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
  //         child: DropdownButtonFormField<String>(
  //           value: _selectedCurrency,
  //           decoration: const InputDecoration(
  //             labelText: 'عرض الأسعار بعملة',
  //             border: OutlineInputBorder(),
  //             contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  //           ),
  //           items: currencies
  //               .toSet()
  //               .toList()
  //               .map((c) => DropdownMenuItem(value: c, child: Text(c)))
  //               .toList(),
  //           onChanged: (value) => setState(() => _selectedCurrency = value),
  //         ),
  //       );
  //     },
  //   );
  // }

  Widget _buildBody(BuildContext context, InventoryState state) {
    if (state.status == InventoryStatus.loading && state.products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == InventoryStatus.failure) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(state.errorMessage ?? 'حدث خطأ'),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _inventoryCubit.refresh(),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }
    if (state.products.isEmpty) {
      return const Center(child: Text('لا توجد منتجات.'));
    }

    return _buildDataTable(context, state);
  }

  Widget _buildDataTable(BuildContext context, InventoryState state) {
    return RefreshIndicator(
      onRefresh: () => _inventoryCubit.refresh(),
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            showCheckboxColumn: false,
            columns: const [
              DataColumn(label: Text('الصنف')),
              DataColumn(label: Text('الكمية'), numeric: true),
              DataColumn(label: Text('سعر البيع'), numeric: true),
              DataColumn(label: Text('إجراءات')),
            ],
            rows: [
              ...state.products.map((product) {
                return DataRow(
                  onSelectChanged: (selected) {
                    if (selected ?? false) _showProductDetailsDialog(product);
                  },
                  cells: [
                    DataCell(Text(product.name)),
                    DataCell(Text(product.quantity.toString())),
                    DataCell(
                      Text('${product.sellingPrice.toStringAsFixed(2)}'),
                    ),
                    DataCell(_buildActionButtons(product)),
                  ],
                );
              }).toList(),
              if (state.status == InventoryStatus.loadingMore)
                const DataRow(
                  cells: [
                    DataCell(Center(child: CircularProgressIndicator())),
                    DataCell(Text('')),
                    DataCell(Text('')),
                    DataCell(Text('')),
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
        title: Text(product.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الباركود: ${product.barcode ?? 'لا يوجد'}'),
            const Divider(),
            Text('الكمية المتاحة: ${product.quantity}'),
            const Divider(),
            Text('سعر التكلفة: ${product.costPrice.toStringAsFixed(2)}'),
            Text('سعر البيع: ${product.sellingPrice.toStringAsFixed(2)}'),
            const Divider(),
            Text(
              'تاريخ الإضافة: ${DateFormat('yyyy-MM-dd', 'ar').format(product.createdAt)}',
            ),
          ],
        ),
        actions: [
          _buildActionButtons(product, fromDialog: true),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إغلاق'),
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8.0,
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
              size: 16,
            )
          : null,
      label: Text(label),
      onPressed: () => _inventoryCubit.changeSort(sortBy: sortBy),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey,
        ),
      ),
      backgroundColor: isSelected
          ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
          : Colors.transparent,
    );
  }
}
