import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hasbni/core/services/currency_converter_service.dart';
import 'package:hasbni/core/services/search_service.dart';
import 'package:hasbni/data/models/exchange_rate_model.dart';
import 'package:hasbni/data/models/product_model.dart';
import 'package:hasbni/data/models/profile_model.dart';
import 'package:hasbni/data/models/sale_detail_model.dart';
import 'package:hasbni/data/models/sale_model.dart';
import 'package:hasbni/presentation/cubits/profile/profile_cubit.dart';
import 'package:hasbni/presentation/cubits/profile/profile_state.dart';
import 'package:hasbni/presentation/cubits/sale_detail/sale_detail_cubit.dart';
import 'package:hasbni/presentation/cubits/sales/sales_cubit.dart';
import 'package:hasbni/presentation/cubits/sales/sales_state.dart';
import 'package:hasbni/presentation/cubits/session/session_cubit.dart';
import 'package:hasbni/presentation/screens/inventory/add_edit_product_screen.dart';
import 'package:hasbni/presentation/widgets/product_search_delegate.dart';
import 'widgets/edit_sale_item_dialog.dart';

class SalesScreen extends StatelessWidget {
  final bool isExchangeMode;
  final SaleDetailItem? itemToExchange;
  final int? returnQuantity;
  final SaleDetailCubit? saleDetailCubit;

  const SalesScreen({
    super.key,
    this.isExchangeMode = false,
    this.itemToExchange,
    this.returnQuantity,
    this.saleDetailCubit,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              SalesCubit(sessionCubit: context.read<SessionCubit>()),
        ),
        BlocProvider(create: (context) => ProfileCubit()..loadProfile()),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(isExchangeMode ? 'فاتورة استبدال' : 'فاتورة بيع جديدة'),
        ),
        body: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, profileState) {
            if (profileState.status == ProfileStatus.loading ||
                profileState.status == ProfileStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (profileState.status == ProfileStatus.failure ||
                profileState.profile == null) {
              return Center(
                child: Text(
                  profileState.errorMessage ?? 'فشل تحميل بيانات المتجر',
                ),
              );
            }

            return _SalesContent(
              profile: profileState.profile!,
              isExchangeMode: isExchangeMode,
              itemToExchange: itemToExchange,
              returnQuantity: returnQuantity,
              saleDetailCubit: saleDetailCubit,
            );
          },
        ),
      ),
    );
  }
}

class _SalesContent extends StatefulWidget {
  final Profile profile;
  final bool isExchangeMode;
  final SaleDetailItem? itemToExchange;
  final int? returnQuantity;
  final SaleDetailCubit? saleDetailCubit;

  const _SalesContent({
    required this.profile,
    required this.isExchangeMode,
    this.itemToExchange,
    this.returnQuantity,
    this.saleDetailCubit,
  });

  @override
  State<_SalesContent> createState() => _SalesContentState();
}

class _SalesContentState extends State<_SalesContent> {
  String _selectedPaymentCurrency = 'USD';

  @override
  Widget build(BuildContext context) {
    final converter = CurrencyConverterService(widget.profile);

    return BlocConsumer<SalesCubit, SalesState>(
      listener: (context, salesState) {
        if (salesState.status == SalesStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'تمت العملية بنجاح. رقم الفاتورة: ${salesState.lastSaleId}',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
          if (widget.isExchangeMode) Navigator.of(context).pop();
        } else if (salesState.status == SalesStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(salesState.errorMessage ?? 'حدث خطأ'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, salesState) {
        return Column(
          children: [
            if (widget.isExchangeMode) _buildExchangeHeader(context, converter),
            _buildActionButtons(context),
            const Divider(),
            _buildTableHeader(context),
            
            // --- FIX: KeyedSubtree forces rebuild when currency changes ---
            Expanded(
              key: ValueKey(_selectedPaymentCurrency), 
              child: salesState.cart.isEmpty
                  ? _buildEmptyCart(context)
                  : ListView.builder(
                      itemCount: salesState.cart.length,
                      itemBuilder: (ctx, index) {
                        final item = salesState.cart[index];
                        return _buildSaleItemRow(
                            context, item, index + 1, converter);
                      },
                    ),
            ),
            
            if (salesState.cart.isNotEmpty)
              _SummaryBarView(
                salesState: salesState,
                profile: widget.profile,
                isExchangeMode: widget.isExchangeMode,
                itemToExchange: widget.itemToExchange,
                returnQuantity: widget.returnQuantity,
                saleDetailCubit: widget.saleDetailCubit,
                selectedCurrency: _selectedPaymentCurrency,
                onCurrencyChanged: (newCurrency) {
                  print("Currency Changed to: $newCurrency"); // Debug
                  setState(() {
                    _selectedPaymentCurrency = newCurrency;
                  });
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_cart_outlined,
              size: 100, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'السلة فارغة',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showSearch(context),
            icon: const Icon(Icons.search),
            label: const Text('البحث عن منتج'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSearch(BuildContext context) async {
    final salesCubit = context.read<SalesCubit>();
    final product = await showSearch<Product?>(
      context: context,
      delegate: ProductSearchDelegate(),
    );
    if (product != null) {
      salesCubit.addProductToCart(product);
    }
  }

  Widget _buildExchangeHeader(
      BuildContext context, CurrencyConverterService converter) {
    final returnedValueUsd =
        widget.itemToExchange!.priceAtSale * widget.returnQuantity!;
    final displayedValue =
        converter.convert(returnedValueUsd, _selectedPaymentCurrency);

    return Container(
      color: Colors.amber.withOpacity(0.2),
      padding: const EdgeInsets.all(12),
      child: Center(
        child: Text(
          'استبدال ${widget.returnQuantity} من "${widget.itemToExchange!.productName}"\n'
          'قيمة المرتجع: ${displayedValue.toStringAsFixed(2)} $_selectedPaymentCurrency',
          style: const TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final cubit = context.read<SalesCubit>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('بحث عن منتج'),
              onPressed: () => _showSearch(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('مسح باركود'),
              onPressed: () async {
                final barcode = await Navigator.of(context).push<String>(
                  MaterialPageRoute(
                    builder: (_) => const BarcodeScannerScreen(),
                  ),
                );
                if (barcode != null && barcode.isNotEmpty) {
                  final searchService = SearchService();
                  final products = await searchService.searchProducts(barcode);
                  if (products.length == 1) {
                    cubit.addProductToCart(products.first);
                  } else if (products.length > 1) {
                    final selectedProduct = await showSearch<Product?>(
                      context: context,
                      delegate: ProductSearchDelegate(),
                      query: barcode,
                    );
                    if (selectedProduct != null) {
                      cubit.addProductToCart(selectedProduct);
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('لم يتم العثور على منتج.')),
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).splashColor,
      child: Row(
        children: [
          const Expanded(
              flex: 1,
              child: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
          const Expanded(
              flex: 5,
              child:
                  Text('الصنف', style: TextStyle(fontWeight: FontWeight.bold))),
          const Expanded(
              flex: 3,
              child: Text('الكمية',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
            flex: 3,
            child: Text(
              'السعر ($_selectedPaymentCurrency)',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'الإجمالي ($_selectedPaymentCurrency)',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleItemRow(BuildContext context, SaleItem item, int index,
      CurrencyConverterService converter) {
    
    // --- DEBUG ---
    // print("Row building for ${item.product.name}. Currency: $_selectedPaymentCurrency");
    
    final price =
        converter.convert(item.sellingPrice, _selectedPaymentCurrency);
    final subtotal = converter.convert(item.subtotal, _selectedPaymentCurrency);

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => BlocProvider.value(
            value: context.read<SalesCubit>(),
            child: EditSaleItemDialog(
              item: item,
              currency: 'USD',
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border:
              Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
        ),
        child: Row(
          children: [
            Expanded(
                flex: 1,
                child: Text(index.toString(), textAlign: TextAlign.center)),
            Expanded(
                flex: 5,
                child:
                    Text(item.product.name, overflow: TextOverflow.ellipsis)),
            Expanded(
                flex: 3,
                child: Text(item.quantity.toString(),
                    textAlign: TextAlign.center)),
            Expanded(
              flex: 3,
              child: Text(
                price.toStringAsFixed(2),
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                subtotal.toStringAsFixed(2),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryBarView extends StatelessWidget {
  final SalesState salesState;
  final Profile profile;
  final bool isExchangeMode;
  final SaleDetailItem? itemToExchange;
  final int? returnQuantity;
  final SaleDetailCubit? saleDetailCubit;

  final String selectedCurrency;
  final ValueChanged<String> onCurrencyChanged;

  const _SummaryBarView({
    required this.salesState,
    required this.profile,
    required this.isExchangeMode,
    this.itemToExchange,
    this.returnQuantity,
    this.saleDetailCubit,
    required this.selectedCurrency,
    required this.onCurrencyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final converter = CurrencyConverterService(profile);

    final List<ExchangeRate> availableRates = [
      const ExchangeRate(id: -1, currencyCode: 'USD', rateToUsd: 1.0),
      ...profile.exchangeRates,
    ];
    // Remove duplicates if any
    final uniqueCodes = <String>{};
    final uniqueRates = <ExchangeRate>[];
    for(var rate in availableRates) {
        if(uniqueCodes.add(rate.currencyCode)) {
            uniqueRates.add(rate);
        }
    }

    String title = 'الإجمالي';
    String buttonText = 'إتمام البيع';
    double basePriceUsd = salesState.totalPrice;

    if (isExchangeMode) {
      title = 'إجمالي السلة الجديدة';
      buttonText = 'إتمام الاستبدال';
    }

    final double displayPrice =
        converter.convert(basePriceUsd, selectedCurrency);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 10,
      child: Padding(
        padding: const EdgeInsets.all(16.0)
            .copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedCurrency,
              decoration: const InputDecoration(labelText: 'عملة الدفع'),
              items: uniqueRates
                  .map((rate) => DropdownMenuItem(value: rate.currencyCode, child: Text(rate.currencyCode)))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  onCurrencyChanged(value);
                }
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                Text(
                  '${displayPrice.abs().toStringAsFixed(2)} $selectedCurrency',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle:
                      const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onPressed: salesState.cart.isEmpty ||
                        salesState.status == SalesStatus.loading
                    ? null
                    : () {
                        final selectedRateObject = uniqueRates.firstWhere(
                          (r) => r.currencyCode == selectedCurrency,
                        );

                        if (isExchangeMode) {
                          assert(saleDetailCubit != null);
                          saleDetailCubit!.exchangeItems(
                            saleItemIdToReturn: itemToExchange!.saleItemId,
                            returnQuantity: returnQuantity!,
                            newItems: salesState.cart,
                            currencyCode: selectedRateObject.currencyCode,
                            rateToUsdAtSale: selectedRateObject.rateToUsd,
                          );
                        } else {
                          context.read<SalesCubit>().completeSale(
                            currencyCode: selectedCurrency,
                            rates: uniqueRates,
                          );
                        }
                      },
                child: salesState.status == SalesStatus.loading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white))
                    : Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}