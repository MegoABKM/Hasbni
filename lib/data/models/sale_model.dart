// lib/data/models/sale_model.dart
import 'package:equatable/equatable.dart';
import 'package:hasbni/data/models/product_model.dart';

// ignore: must_be_immutable
class SaleItem extends Equatable {
  final Product product;
  int quantity;
  double sellingPrice;

  SaleItem({required this.product, this.quantity = 1})
    : sellingPrice = product.sellingPrice;

  double get subtotal => sellingPrice * quantity;

  @override
  List<Object?> get props => [product, quantity, sellingPrice];

  Map<String, dynamic> toRpcJson() {
    return {
      'product_id': product.id,
      'quantity': quantity,
      'price': sellingPrice,
    };
  }
}

class Sale extends Equatable {
  final int id;
  final double totalPrice;
  final DateTime createdAt;
  final String currencyCode;
  const Sale({
    required this.id,
    required this.totalPrice,
    required this.currencyCode,
    required this.createdAt,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'],
      totalPrice: (json['total_price'] as num).toDouble(),
      currencyCode: json['currency_code'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  @override
  List<Object?> get props => [id, totalPrice, currencyCode, createdAt];
}
