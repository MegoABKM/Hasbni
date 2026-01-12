import 'package:hasbni/core/constants/api_constants.dart';
import 'package:hasbni/core/services/api_services.dart';
import 'package:hasbni/core/services/database_service.dart';
import 'package:hasbni/data/models/product_model.dart';
import 'package:sqflite/sqflite.dart';

class SyncService {
  final ApiService _api = ApiService();
  final DatabaseService _db = DatabaseService();

  // Call this when app starts or "Sync" button pressed
  Future<void> syncEverything() async {
    print("🔄 Starting Sync...");
    try {
      await _syncProducts();
      await _syncSales();
      // Add other syncs (expenses, etc) here...

      await _pullLatestData(); // Products
      await _pullProfile(); // <--- ADD THIS

      print("✅ Sync Complete");
    } catch (e) {
      print("❌ Sync Error: $e");
    }
  }

  // --- 1. Push Products ---
  Future<void> _syncProducts() async {
    final db = await _db.database;
    // Get unsynced rows
    final rows = await db.query('products', where: 'sync_status != 0');

    for (var row in rows) {
      final status = row['sync_status'];
      final localId = row['local_id'];
      final serverId = row['server_id'];

      try {
        if (status == 1) {
          // CREATE
          final response = await _api.post(ApiConstants.products, {
            'name': row['name'],
            'barcode': row['barcode'],
            'quantity': row['quantity'],
            'cost_price': row['cost_price'],
            'selling_price': row['selling_price'],
          });
          // Update local with server ID
          await db.update(
              'products', {'server_id': response['id'], 'sync_status': 0},
              where: 'local_id = ?', whereArgs: [localId]);
        } else if (status == 2 && serverId != null) {
          // UPDATE
          await _api.put('${ApiConstants.products}/$serverId', {
            'name': row['name'],
            'quantity': row['quantity'],
            // ... other fields
          });
          await db.update('products', {'sync_status': 0},
              where: 'local_id = ?', whereArgs: [localId]);
        } else if (status == 3 && serverId != null) {
          // DELETE
          await _api.delete('${ApiConstants.products}/$serverId');
          await db
              .delete('products', where: 'local_id = ?', whereArgs: [localId]);
        }
      } catch (e) {
        print("Error syncing product $localId: $e");
      }
    }
  }

  // --- 2. Push Sales ---
  Future<void> _syncSales() async {
    final db = await _db.database;
    final unsyncedSales = await db.query('sales', where: 'sync_status = 1');

    for (var sale in unsyncedSales) {
      try {
        // Get Items
        final items = await db.rawQuery('''
          SELECT si.*, p.server_id as product_server_id 
          FROM sale_items si
          LEFT JOIN products p ON si.product_local_id = p.local_id
          WHERE si.sale_local_id = ?
        ''', [sale['local_id']]);

        // --- ADD THIS CHECK ---
        bool hasUnsyncedProducts =
            items.any((item) => item['product_server_id'] == null);
        if (hasUnsyncedProducts) {
          print(
              "⚠️ Skipping Sale ${sale['local_id']} because it contains unsynced products.");
          continue; // Skip this sale, try again next sync
        }
// ----------------------

        // Construct RPC Json
        final rpcItems = items
            .map((item) => {
                  'product_id': item['product_server_id'], // MUST use Server ID
                  'quantity': item['quantity'],
                  'price': item['price'],
                })
            .toList();

        final responseId = await _api.post(ApiConstants.createSale, {
          'p_sale_items_data': rpcItems,
          'p_currency_code': sale['currency_code'],
          'p_rate_to_usd_at_sale': sale['rate_to_usd_at_sale'],
          'p_employee_id': sale['employee_id'],
        });

        // Mark synced
        await db.update('sales',
            {'server_id': int.parse(responseId.toString()), 'sync_status': 0},
            where: 'local_id = ?', whereArgs: [sale['local_id']]);
      } catch (e) {
        print("Error syncing sale ${sale['local_id']}: $e");
      }
    }
  }

  // --- 3. Pull Data (Initial Load / Refresh) ---
  Future<void> _pullLatestData() async {
    final db = await _db.database;

    // Fetch Products from API
    // Note: In a real app, send 'last_sync_timestamp' to get only changes
    final response = await _api.get('${ApiConstants.products}?limit=1000');
    final List apiProducts = response['data'];

    await db.transaction((txn) async {
      for (var p in apiProducts) {
        // Check if exists locally
        final existing = await txn
            .query('products', where: 'server_id = ?', whereArgs: [p['id']]);

        if (existing.isEmpty) {
          // Insert
          await txn.insert('products', {
            'server_id': p['id'],
            'name': p['name'],
            'barcode': p['barcode'],
            'quantity': p['quantity'],
            'cost_price': p['cost_price'],
            'selling_price': p['selling_price'],
            'created_at': p['created_at'],
            'sync_status': 0, // Clean
          });
        } else {
          // Update (Only if local isn't dirty)
          if (existing.first['sync_status'] == 0) {
            await txn.update(
                'products',
                {
                  'name': p['name'],
                  'quantity': p['quantity'],
                  // update other fields...
                },
                where: 'server_id = ?',
                whereArgs: [p['id']]);
          }
        }
      }
    });
  }

  Future<void> _pullProfile() async {
    // Just calling getCurrentUserProfile in Repository will trigger
    // fetch from API -> Save to Local logic we just wrote.
    // However, we need to access the repo logic.
    // Ideally, SyncService shouldn't depend on Repos, but for simplicity:

    final response = await _api.get(ApiConstants.profiles);
    final profile = Product.fromJson(response); // Import Profile model

    // We need to duplicate the save logic or make ProfileRepository accessible.
    // Use raw DB calls here to avoid circular dependencies if any.
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.insert(
          'profiles',
          {
            'id': 1,
            'shop_name': response['shop_name'],
            'address': response['address'],
            'phone_number': response['phone_number'],
            'city': response['city'],
            'has_manager_password': (response['has_manager_password'] == true ||
                    response['has_manager_password'] == 1)
                ? 1
                : 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace);

      await txn.delete('exchange_rates');
      if (response['exchange_rates'] != null) {
        for (var rate in response['exchange_rates']) {
          await txn.insert('exchange_rates', {
            'currency_code': rate['currency_code'],
            'rate_to_usd': rate['rate_to_usd'],
          });
        }
      }
    });
  }
}
