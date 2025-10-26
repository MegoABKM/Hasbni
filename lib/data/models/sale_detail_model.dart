// lib/data/models/sale_detail_model.dart
import 'package:equatable/equatable.dart';

class SaleDetailItem extends Equatable {
  final int saleItemId;
  final int productId;
  final String productName;
  final int quantitySold;
  final int returnedQuantity;
  final double priceAtSale;

  int get returnableQuantity => quantitySold - returnedQuantity;

  const SaleDetailItem({
    required this.saleItemId,
    required this.productId,
    required this.productName,
    required this.quantitySold,
    required this.returnedQuantity,
    required this.priceAtSale,
  });

  factory SaleDetailItem.fromJson(Map<String, dynamic> json) {
    return SaleDetailItem(
      saleItemId: json['sale_item_id'],
      productId: json['product_id'],
      productName: json['product_name'],
      quantitySold: json['quantity_sold'],
      returnedQuantity: json['returned_quantity'],
      priceAtSale: (json['price_at_sale'] as num).toDouble(),
    );
  }
  @override
  List<Object?> get props => [saleItemId, quantitySold, returnedQuantity];
}

class SaleDetail extends Equatable {
  final int id;
  final double totalPrice;
  final String currencyCode; // <-- NEW: The currency this sale was made in
  final DateTime createdAt;
  final List<SaleDetailItem> items;

  const SaleDetail({
    required this.id,
    required this.totalPrice,
    required this.currencyCode, // <-- NEW
    required this.createdAt,
    required this.items,
  });

  factory SaleDetail.fromJson(Map<String, dynamic> json) {
    var itemsList = <SaleDetailItem>[];
    if (json['items'] != null) {
      json['items'].forEach((v) {
        itemsList.add(SaleDetailItem.fromJson(v));
      });
    }
    return SaleDetail(
      id: json['id'],
      totalPrice: (json['total_price'] as num).toDouble(),
      currencyCode: json['currency_code'] ?? 'USD', // <-- NEW, with a fallback
      createdAt: DateTime.parse(json['created_at']),
      items: itemsList,
    );
  }
  @override
  List<Object?> get props => [id, items, currencyCode];
}
