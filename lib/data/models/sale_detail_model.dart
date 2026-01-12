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
      saleItemId: json['id'], // Note: standard Laravel is 'id', check your response
      productId: json['product_id'] ?? 0,
      productName: json['product_name_snapshot'] ?? json['product_name'] ?? 'Unknown',
      quantitySold: int.tryParse(json['quantity_sold'].toString()) ?? 0,
      returnedQuantity: int.tryParse(json['returned_quantity'].toString()) ?? 0,
      // FIX: Safely parse decimal string
      priceAtSale: double.tryParse(json['price_at_sale'].toString()) ?? 0.0,
    );
  }
  @override
  List<Object?> get props => [saleItemId, quantitySold, returnedQuantity];
}

class SaleDetail extends Equatable {
  final int id;
  final double totalPrice;
  final String currencyCode; 
  final DateTime createdAt;
  final List<SaleDetailItem> items;

  const SaleDetail({
    required this.id,
    required this.totalPrice,
    required this.currencyCode, 
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
      // FIX: Safely parse decimal string
      totalPrice: double.tryParse(json['total_price'].toString()) ?? 0.0,
      currencyCode: json['currency_code'] ?? 'USD', 
      createdAt: DateTime.parse(json['created_at']),
      items: itemsList,
    );
  }
  @override
  List<Object?> get props => [id, items, currencyCode];
}