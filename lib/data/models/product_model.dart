import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final int id; // الآن هو رقم وليس نص
  final String name;
  final String? barcode; // يمكن أن يكون فارغاً
  final int quantity;
  final double costPrice;
  final double sellingPrice;
  final DateTime createdAt; // أضفنا تاريخ الإنشاء

  const Product({
    required this.id,
    required this.name,
    this.barcode,
    required this.quantity,
    required this.costPrice,
    required this.sellingPrice,
    required this.createdAt,
  });

  // دالة لتحويل JSON القادم من Supabase إلى كائن Product
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      barcode: json['barcode'],
      quantity: json['quantity'],
      // Supabase يرجع الأرقام كـ num، لذا نحولها إلى double
      costPrice: (json['cost_price'] as num).toDouble(),
      sellingPrice: (json['selling_price'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  // دالة لتحويل كائن Product إلى JSON لإرساله إلى Supabase
  Map<String, dynamic> toJson() {
    return {
      // لا نرسل الـ id أو created_at عند الإنشاء أو التعديل
      'name': name,
      'barcode': barcode,
      'quantity': quantity,
      'cost_price': costPrice,
      'selling_price': sellingPrice,
      // user_id سيتم إضافته تلقائياً بواسطة Supabase RLS
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
