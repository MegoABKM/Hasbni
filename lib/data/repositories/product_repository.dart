import 'package:hasbni/core/services/database_service.dart';
import 'package:hasbni/data/models/product_model.dart';

class ProductRepository {
  final DatabaseService _db = DatabaseService();

  Future<List<Product>> getProducts({
    required int page,
    required int limit,
    String? sortBy,
    bool? ascending,
    String? searchQuery,
  }) async {
    final db = await _db.database;

    String query = 'SELECT * FROM products WHERE sync_status != 3';
    List<dynamic> args = [];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query += ' AND (name LIKE ? OR barcode LIKE ?)';
      args.add('%$searchQuery%');
      args.add('%$searchQuery%');
    }

    // Default Sort: Newest created locally first
    String orderCol = 'local_id';
    String dir = 'DESC';
    
    if (sortBy != null) {
      orderCol = sortBy;
      dir = (ascending == true) ? 'ASC' : 'DESC';
    }
    
    query += ' ORDER BY $orderCol $dir LIMIT ? OFFSET ?';
    args.add(limit);
    args.add(page * limit);

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, args);
    return maps.map((e) => Product.fromSqlite(e)).toList();
  }

  Future<void> addProduct(Map<String, dynamic> productData) async {
    final db = await _db.database;
    
    final product = Product(
      name: productData['name'],
      barcode: productData['barcode'],
      quantity: productData['quantity'],
      costPrice: productData['cost_price'],
      sellingPrice: productData['selling_price'],
      createdAt: DateTime.now(),
      syncStatus: 1, // 1 = Created Locally
    );
    
    // Perform insert and print result for debugging
    int id = await db.insert('products', product.toSqlite());
    print("✅ Product Added to SQLite with local_id: $id");
  }

  // ... updateProduct and deleteProduct remain the same ...
   Future<void> updateProduct(int productLocalId, Map<String, dynamic> data) async {
    final db = await _db.database;
    final existing = await db.query('products', where: 'local_id = ?', whereArgs: [productLocalId]);
    
    int newStatus = 2; // Updated
    if (existing.isNotEmpty && existing.first['sync_status'] == 1) {
      newStatus = 1; // Still just 'Created' locally
    }
    data['sync_status'] = newStatus;
    await db.update('products', data, where: 'local_id = ?', whereArgs: [productLocalId]);
  }

  Future<void> deleteProduct(int productLocalId) async {
    final db = await _db.database;
    final existing = await db.query('products', where: 'local_id = ?', whereArgs: [productLocalId]);
    if (existing.isEmpty) return;

    if (existing.first['sync_status'] == 1) {
      await db.delete('products', where: 'local_id = ?', whereArgs: [productLocalId]);
    } else {
      await db.update('products', {'sync_status': 3}, where: 'local_id = ?', whereArgs: [productLocalId]);
    }
  }
}