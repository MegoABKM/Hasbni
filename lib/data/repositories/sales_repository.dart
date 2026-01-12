import 'package:hasbni/core/services/database_service.dart';
import 'package:hasbni/data/models/sale_detail_model.dart';
import 'package:hasbni/data/models/sale_model.dart';
import 'package:sqflite/sqflite.dart';

class SalesRepository {
  final DatabaseService _db = DatabaseService();

  // Create Sale (Offline)
  Future<int> createSale({
    required List<SaleItem> items,
    required String currencyCode,
    required double rateToUsdAtSale,
    int? employeeId,
  }) async {
    final db = await _db.database;
    double totalPrice = 0;

    return await db.transaction((txn) async {
      for (var item in items) {
        totalPrice += (item.sellingPrice * item.quantity);
        // Decrement Inventory Locally
        if (item.product.localId != null) {
           await txn.rawUpdate(
             'UPDATE products SET quantity = quantity - ?, sync_status = CASE WHEN sync_status = 0 THEN 2 ELSE sync_status END WHERE local_id = ?', 
             [item.quantity, item.product.localId]
           );
        }
      }

      // Insert Sale
      int saleLocalId = await txn.insert('sales', {
        'total_price': totalPrice,
        'currency_code': currencyCode,
        'rate_to_usd_at_sale': rateToUsdAtSale,
        'employee_id': employeeId,
        'created_at': DateTime.now().toIso8601String(),
        'sync_status': 1, // 1 = Created Locally
      });

      // Insert Items
      for (var item in items) {
        await txn.insert('sale_items', {
          'sale_local_id': saleLocalId,
          'product_local_id': item.product.localId, 
          'quantity': item.quantity,
          'price': item.sellingPrice,
          'cost_price_at_sale': item.product.costPrice,
        });
      }
      return saleLocalId;
    });
  }

  // Get History (Offline)
  Future<List<Sale>> getSalesHistory({required int page, required int limit}) async {
    final db = await _db.database;
    final maps = await db.query(
      'sales',
      orderBy: 'local_id DESC', // Use local_id for sorting offline
      limit: limit,
      offset: page * limit,
    );
    
    return maps.map((e) => Sale.fromJson({
      'id': e['local_id'], // Map local_id to id for UI
      'total_price': e['total_price'],
      'currency_code': e['currency_code'],
      'created_at': e['created_at'],
    })).toList();
  }

  // --- MISSING METHOD 1: Get Details ---
  Future<SaleDetail> getSaleDetails(int saleLocalId) async {
    final db = await _db.database;
    
    // 1. Get Sale Header
    final saleMaps = await db.query('sales', where: 'local_id = ?', whereArgs: [saleLocalId]);
    if (saleMaps.isEmpty) throw Exception('Sale not found');
    final sale = saleMaps.first;

    // 2. Get Items with Product Name join
    final itemsMaps = await db.rawQuery('''
      SELECT si.*, p.name as product_name, p.server_id as product_server_id
      FROM sale_items si
      LEFT JOIN products p ON si.product_local_id = p.local_id
      WHERE si.sale_local_id = ?
    ''', [saleLocalId]);

    // 3. Map to Models
    final items = itemsMaps.map((row) {
      return SaleDetailItem(
        saleItemId: row['local_id'] as int,
        productId: (row['product_server_id'] ?? 0) as int, // Best effort
        productName: (row['product_name'] ?? 'Unknown') as String,
        quantitySold: row['quantity'] as int,
        returnedQuantity: (row['returned_quantity'] ?? 0) as int,
        priceAtSale: (row['price'] as num).toDouble(),
      );
    }).toList();

    return SaleDetail(
      id: sale['local_id'] as int,
      totalPrice: (sale['total_price'] as num).toDouble(),
      currencyCode: sale['currency_code'] as String,
      createdAt: DateTime.parse(sale['created_at'] as String),
      items: items,
    );
  }

  // --- MISSING METHOD 2: Process Return ---
  Future<void> processReturn(int saleItemLocalId, int returnQuantity) async {
    final db = await _db.database;
    
    await db.transaction((txn) async {
      // 1. Get Sale Item
      final itemResult = await txn.query('sale_items', where: 'local_id = ?', whereArgs: [saleItemLocalId]);
      if (itemResult.isEmpty) throw Exception('Item not found');
      final item = itemResult.first;

      // 2. Update Returned Quantity
      await txn.rawUpdate(
        'UPDATE sale_items SET returned_quantity = returned_quantity + ? WHERE local_id = ?',
        [returnQuantity, saleItemLocalId]
      );

      // 3. Restore Product Inventory
      if (item['product_local_id'] != null) {
        await txn.rawUpdate(
          'UPDATE products SET quantity = quantity + ?, sync_status = 2 WHERE local_id = ?',
          [returnQuantity, item['product_local_id']]
        );
      }

      // 4. Update Sale Header Total (Reduce price)
      final refundAmount = (item['price'] as num) * returnQuantity;
      await txn.rawUpdate(
        'UPDATE sales SET total_price = total_price - ?, sync_status = 2 WHERE local_id = ?',
        [refundAmount, item['sale_local_id']]
      );
    });
  }

  // --- MISSING METHOD 3: Process Exchange ---
  Future<Map<String, dynamic>> processExchange({
    required int saleItemIdToReturn,
    required int returnQuantity,
    required List<SaleItem> newItems,
    required String currencyCode,
    required double rateToUsdAtSale,
    int? employeeId,
  }) async {
    final db = await _db.database;
    
    return await db.transaction((txn) async {
      // 1. Process Return Logic inside this transaction
      final itemResult = await txn.query('sale_items', where: 'local_id = ?', whereArgs: [saleItemIdToReturn]);
      final item = itemResult.first;
      
      // Update returned qty
      await txn.rawUpdate(
        'UPDATE sale_items SET returned_quantity = returned_quantity + ? WHERE local_id = ?',
        [returnQuantity, saleItemIdToReturn]
      );
      
      // Restore inventory
      if (item['product_local_id'] != null) {
        await txn.rawUpdate(
          'UPDATE products SET quantity = quantity + ?, sync_status = 2 WHERE local_id = ?',
          [returnQuantity, item['product_local_id']]
        );
      }

      final returnedValue = (item['price'] as num) * returnQuantity;

      // 2. Create New Sale Logic
      double newSaleTotal = 0;
      for (var newItem in newItems) {
        newSaleTotal += (newItem.sellingPrice * newItem.quantity);
        if (newItem.product.localId != null) {
           await txn.rawUpdate(
             'UPDATE products SET quantity = quantity - ?, sync_status = 2 WHERE local_id = ?', 
             [newItem.quantity, newItem.product.localId]
           );
        }
      }

      int newSaleId = await txn.insert('sales', {
        'total_price': newSaleTotal,
        'currency_code': currencyCode,
        'rate_to_usd_at_sale': rateToUsdAtSale,
        'employee_id': employeeId,
        'created_at': DateTime.now().toIso8601String(),
        'sync_status': 1,
      });

      for (var newItem in newItems) {
        await txn.insert('sale_items', {
          'sale_local_id': newSaleId,
          'product_local_id': newItem.product.localId, 
          'quantity': newItem.quantity,
          'price': newItem.sellingPrice,
          'cost_price_at_sale': newItem.product.costPrice,
        });
      }

      return {
        'new_sale_id': newSaleId,
        'price_difference': newSaleTotal - returnedValue,
        'currency_code': currencyCode,
      };
    });
  }
}