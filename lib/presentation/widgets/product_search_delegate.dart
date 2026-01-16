
import 'package:flutter/material.dart';
import 'package:hasbni/core/services/search_service.dart';
import 'package:hasbni/core/services/sound_service.dart';
import 'package:hasbni/data/models/product_model.dart';
import 'package:hasbni/presentation/screens/inventory/add_edit_product_screen.dart';

class ProductSearchDelegate extends SearchDelegate<Product?> {
  final SearchService _searchService = SearchService();

  @override
  String get searchFieldLabel => 'ابحث بالاسم أو الباركود...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
     IconButton(
  icon: const Icon(Icons.qr_code_scanner),
  tooltip: 'امسح الباركود',
  onPressed: () async {
    final barcodeValue = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerScreen(),
      ),
    );
    // --- FIX: Add .trim() here ---
    if (barcodeValue != null && barcodeValue.trim().isNotEmpty) {
      SoundService().playBeep();
      query = barcodeValue.trim(); // Clean it before setting the query
      showResults(context);
    }
  },
),
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.trim().isEmpty) {
      return const Center(
        child: Text('الرجاء إدخال اسم منتج أو باركود للبحث.'),
      );
    }

    return FutureBuilder<List<Product>>(
      future: _searchService.searchProducts(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('حدث خطأ أثناء البحث.'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('لم يتم العثور على منتج يطابق "$query"'));
        }

        final results = snapshot.data!;
        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final product = results[index];
            return ListTile(
              title: Text(product.name),
              subtitle: Text('الكمية المتاحة: ${product.quantity}'),
              trailing: Text('${product.sellingPrice.toStringAsFixed(2)} د.ل'),
              onTap: () => close(context, product),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'أدخل بحثك أو امسح باركود',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
