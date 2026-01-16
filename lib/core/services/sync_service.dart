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
      // 1. PUSH Changes to Server
      await _syncCategories(); 
      await _syncEmployees(); // <--- ADD THIS HERE (Before Sales)
      await _syncProducts();
      await _syncSales();     // Sales depends on Employees and Products having Server IDs
      await _syncExpenses();
      await _syncWithdrawals();

      // 2. PULL Data from Server (Refresh)
      await _pullLatestData();   // Products
      await _pullProfile();
      await _pullCategories(); // <--- Add this
      await _pullExpenses();   // <--- ADD
      await _pullWithdrawals(); // <--- ADD

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
      // FIX: Corrected typo 'server _id' -> 'server_id'
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
        // --- FIX START: Resolve Employee Server ID ---
        int? serverEmployeeId;
        final localEmployeeId = sale['employee_id'];

        if (localEmployeeId != null) {
          final empResult = await db.query(
            'employees',
            columns: ['server_id'],
            where: 'local_id = ?',
            whereArgs: [localEmployeeId],
          );

          if (empResult.isNotEmpty) {
            serverEmployeeId = empResult.first['server_id'] as int?;
          }

          // CRITICAL CHECK:
          // If the employee exists locally but doesn't have a server_id yet
          // (meaning they haven't synced), we CANNOT sync this sale yet.
          // We skip this sale and wait for the next sync cycle.
          if (serverEmployeeId == null) {
            print("⚠️ Skipping Sale ${sale['local_id']}: Employee (Local ID $localEmployeeId) not yet synced to server.");
            continue; 
          }
        }
        // --- FIX END ---

        // Get Items
        final items = await db.rawQuery('''
          SELECT si.*, p.server_id as product_server_id 
          FROM sale_items si
          LEFT JOIN products p ON si.product_local_id = p.local_id
          WHERE si.sale_local_id = ?
        ''', [sale['local_id']]);

        // Check for unsynced products
        bool hasUnsyncedProducts =
            items.any((item) => item['product_server_id'] == null);
        if (hasUnsyncedProducts) {
          print("⚠️ Skipping Sale ${sale['local_id']} because it contains unsynced products.");
          continue; 
        }

        // Construct RPC Json
        final rpcItems = items.map((item) => {
          'product_id': item['product_server_id'], 
          'quantity': item['quantity'],
          'price': item['price'],
        }).toList();

        final responseId = await _api.post(ApiConstants.createSale, {
          'p_sale_items_data': rpcItems,
          'p_currency_code': sale['currency_code'],
          'p_rate_to_usd_at_sale': sale['rate_to_usd_at_sale'],
          'p_employee_id': serverEmployeeId, // <--- CHANGED: Send Server ID, not Local ID
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
    final response = await _api.get(ApiConstants.profiles);
    // ignore: unused_local_variable
    final profile = Product.fromJson(response); 

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

  // --- NEW: Sync Expenses ---
  Future<void> _syncExpenses() async {
    final db = await _db.database;
    final rows = await db.query('expenses', where: 'sync_status != 0');

    for (var row in rows) {
      // FIX: Define localId and serverId here
      final localId = row['local_id'];
      final serverId = row['server_id'];

      // Try to find the server_id for the category
      int? serverCategoryId;
      if (row['category_local_id'] != null) {
        final catRow = await db.query('expense_categories',
            columns: ['server_id'],
            where: 'local_id = ?',
            whereArgs: [row['category_local_id']]);
        if (catRow.isNotEmpty) {
          serverCategoryId = catRow.first['server_id'] as int?;
        }
      }

      try {
        if (row['sync_status'] == 1) {
          // CREATE
          final response = await _api.post(ApiConstants.expenses, {
            'description': row['description'],
            'amount': row['amount'],
            'expense_date': row['expense_date'],
            'currency_code': row['currency_code'],
            'amount_in_currency': row['amount_in_currency'],
            'category_id': serverCategoryId, // Send the mapped Server ID
            'recurrence': row['recurrence'],
          });
          await db.update(
              'expenses', {'server_id': response['id'], 'sync_status': 0},
              where: 'local_id = ?', whereArgs: [localId]);
        } else if (row['sync_status'] == 3 && serverId != null) {
          // DELETE
          await _api.delete('${ApiConstants.expenses}/$serverId');
          await db.delete('expenses',
              where: 'local_id = ?', whereArgs: [localId]);
        }
      } catch (e) {
        print("Sync Expense Error: $e");
      }
    }
  }

  // --- NEW: Sync Withdrawals ---
  Future<void> _syncWithdrawals() async {
    final db = await _db.database;
    final rows = await db.query('withdrawals', where: 'sync_status != 0');

    for (var row in rows) {
      try {
        if (row['sync_status'] == 1) {
          // CREATE
          final response = await _api.post(ApiConstants.withdrawals, {
            'description': row['description'],
            'amount': row['amount'],
            'withdrawal_date': row['withdrawal_date'],
            'currency_code': row['currency_code'],
            'amount_in_currency': row['amount_in_currency'],
          });
          await db.update(
              'withdrawals', {'server_id': response['id'], 'sync_status': 0},
              where: 'local_id = ?', whereArgs: [row['local_id']]);
        } else if (row['sync_status'] == 3 && row['server_id'] != null) {
          // DELETE
          await _api.delete('${ApiConstants.withdrawals}/${row['server_id']}');
          await db.delete('withdrawals',
              where: 'local_id = ?', whereArgs: [row['local_id']]);
        }
      } catch (e) {
        print("Sync Withdrawal Error: $e");
      }
    }
  }

  // --- NEW: Pull Methods (Simplest Approach: Clear & Refill) ---
  Future<void> _pullExpenses() async {
    try {
      final List data = await _api.get(ApiConstants.expenses);
      final db = await _db.database;
      await db.transaction((txn) async {
        // Keep unsynced (status != 0), delete synced (status == 0) to avoid duplicates
        await txn.delete('expenses', where: 'sync_status = 0');
        for (var item in data) {
          // Map Server Category ID to Local Category ID
          int? localCategoryId;
          if (item['category_id'] != null) {
            final catRow = await txn.query('expense_categories',
                columns: ['local_id'],
                where: 'server_id = ?',
                whereArgs: [item['category_id']]);
            if (catRow.isNotEmpty) {
              localCategoryId = catRow.first['local_id'] as int;
            }
          }

          await txn.insert('expenses', {
            'server_id': item['id'],
            'description': item['description'],
            'amount': (item['amount'] as num).toDouble(),
            'amount_in_currency':
                (item['amount_in_currency'] ?? item['amount'] as num).toDouble(),
            'currency_code': item['currency_code'] ?? 'USD',
            'expense_date': item['expense_date'],
            'recurrence': item['recurrence'],
            'category_local_id': localCategoryId,
            'sync_status': 0
          });
        }
      });
    } catch (_) {}
  }

  Future<void> _pullWithdrawals() async {
    try {
      final List data = await _api.get(ApiConstants.withdrawals);
      final db = await _db.database;
      await db.transaction((txn) async {
        await txn.delete('withdrawals', where: 'sync_status = 0');
        for (var item in data) {
          await txn.insert('withdrawals', {
            'server_id': item['id'],
            'description': item['description'],
            'amount': (item['amount'] as num).toDouble(),
            'amount_in_currency':
                (item['amount_in_currency'] ?? item['amount'] as num).toDouble(),
            'currency_code': item['currency_code'] ?? 'USD',
            'withdrawal_date': item['withdrawal_date'],
            'sync_status': 0
          });
        }
      });
    } catch (_) {}
  }

  Future<void> _syncCategories() async {
    final db = await _db.database;
    final rows =
        await db.query('expense_categories', where: 'sync_status != 0');

    for (var row in rows) {
      try {
        if (row['sync_status'] == 1) {
          // CREATE
          final response = await _api
              .post(ApiConstants.expenseCategories, {'name': row['name']});
          await db.update('expense_categories',
              {'server_id': response['id'], 'sync_status': 0},
              where: 'local_id = ?', whereArgs: [row['local_id']]);
        } else if (row['sync_status'] == 3 && row['server_id'] != null) {
          // DELETE
          await _api
              .delete('${ApiConstants.expenseCategories}/${row['server_id']}');
          await db.delete('expense_categories',
              where: 'local_id = ?', whereArgs: [row['local_id']]);
        }
      } catch (e) {
        print("Sync Category Error: $e");
      }
    }
  }

  Future<void> _pullCategories() async {
    try {
      final List data = await _api.get(ApiConstants.expenseCategories);
      final db = await _db.database;
      await db.transaction((txn) async {
        await txn.delete('expense_categories', where: 'sync_status = 0');
        for (var item in data) {
          await txn.insert('expense_categories', {
            'server_id': item['id'],
            'name': item['name'],
            'sync_status': 0
          });
        }
      });
    } catch (_) {}
  }


    Future<void> _syncEmployees() async {
    final db = await _db.database;
    final rows = await db.query('employees', where: 'sync_status != 0');

    for (var row in rows) {
      try {
        if (row['sync_status'] == 1) {
          // CREATE
          final response = await _api.post(ApiConstants.employees, {
            'full_name': row['full_name']
          });
          
          // Update local with server ID
          await db.update(
            'employees', 
            {'server_id': response['id'], 'sync_status': 0},
            where: 'local_id = ?', 
            whereArgs: [row['local_id']]
          );
        } else if (row['sync_status'] == 2 && row['server_id'] != null) {
          // UPDATE
          await _api.put('${ApiConstants.employees}/${row['server_id']}', {
            'full_name': row['full_name']
          });
          await db.update('employees', {'sync_status': 0},
              where: 'local_id = ?', whereArgs: [row['local_id']]);
        } else if (row['sync_status'] == 3 && row['server_id'] != null) {
          // DELETE
          await _api.delete('${ApiConstants.employees}/${row['server_id']}');
          await db.delete('employees',
              where: 'local_id = ?', whereArgs: [row['local_id']]);
        }
      } catch (e) {
        print("Error syncing employee ${row['local_id']}: $e");
      }
    }
  }
}