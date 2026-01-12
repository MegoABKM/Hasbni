import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final int? localId; // SQLite ID (Used for local operations)
  final int? id;      // Server ID (Used for Sync)
  final String name;
  final String? barcode;
  final int quantity;
  final double costPrice;
  final double sellingPrice;
  final DateTime createdAt;
  final int syncStatus; // 0=Synced, 1=Created, 2=Updated, 3=Deleted

  const Product({
    this.localId,
    this.id,
    required this.name,
    this.barcode,
    required this.quantity,
    required this.costPrice,
    required this.sellingPrice,
    required this.createdAt,
    this.syncStatus = 0,
  });

  // From API (Laravel)
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'], // Server ID
      localId: null, // Will be assigned when saving to DB
      name: json['name'] ?? '',
      barcode: json['barcode'],
      quantity: int.tryParse(json['quantity'].toString()) ?? 0,
      costPrice: double.tryParse(json['cost_price'].toString()) ?? 0.0,
      sellingPrice: double.tryParse(json['selling_price'].toString()) ?? 0.0,
      createdAt: DateTime.parse(json['created_at']),
      syncStatus: 0, // Coming from server, so it's synced
    );
  }

  // From SQLite
  factory Product.fromSqlite(Map<String, dynamic> map) {
    return Product(
      localId: map['local_id'],
      id: map['server_id'], // Map 'server_id' col to 'id' field
      name: map['name'],
      barcode: map['barcode'],
      quantity: map['quantity'],
      costPrice: map['cost_price'],
      sellingPrice: map['selling_price'],
      createdAt: DateTime.parse(map['created_at']),
      syncStatus: map['sync_status'],
    );
  }

  // To SQLite
Map<String, dynamic> toSqlite() {
  return {
    if (id != null) 'server_id': id,
    'name': name,
    'barcode': barcode,
    'quantity': quantity,
    'cost_price': costPrice,
    'selling_price': sellingPrice,
    'created_at': createdAt.toIso8601String(),
    'sync_status': syncStatus,
  };
}

  @override
  List<Object?> get props => [localId, id, name, quantity, syncStatus];
}