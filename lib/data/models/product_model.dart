import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final int id; 
  final String name;
  final String? barcode; 
  final int quantity;
  final double costPrice;
  final double sellingPrice;
  final DateTime createdAt; 

  const Product({
    required this.id,
    required this.name,
    this.barcode,
    required this.quantity,
    required this.costPrice,
    required this.sellingPrice,
    required this.createdAt,
  });

  
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      barcode: json['barcode'],
      quantity: json['quantity'],
      
      costPrice: (json['cost_price'] as num).toDouble(),
      sellingPrice: (json['selling_price'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  
  Map<String, dynamic> toJson() {
    return {
      
      'name': name,
      'barcode': barcode,
      'quantity': quantity,
      'cost_price': costPrice,
      'selling_price': sellingPrice,
      
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    barcode,
    quantity,
    costPrice,
    sellingPrice,
    createdAt,
  ];
}
