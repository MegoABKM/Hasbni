import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'hasbni_offline_v2.db');
    // Bump version if you change schema later
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // --- 1. PRODUCTS ---
    await db.execute('''
      CREATE TABLE products (
        local_id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER, 
        name TEXT NOT NULL,
        barcode TEXT,
        quantity INTEGER DEFAULT 0,
        cost_price REAL DEFAULT 0,
        selling_price REAL DEFAULT 0,
        created_at TEXT,
        sync_status INTEGER DEFAULT 0 -- 0=Synced, 1=Created, 2=Updated, 3=Deleted
      )
    ''');

    // --- 2. EMPLOYEES ---
    await db.execute('''
      CREATE TABLE employees (
        local_id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER,
        full_name TEXT NOT NULL,
        sync_status INTEGER DEFAULT 0
      )
    ''');

    // --- 3. EXPENSE CATEGORIES ---
    await db.execute('''
      CREATE TABLE expense_categories (
        local_id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER,
        name TEXT NOT NULL,
        sync_status INTEGER DEFAULT 0
      )
    ''');

    // --- 4. EXPENSES ---
    await db.execute('''
      CREATE TABLE expenses (
        local_id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER,
        description TEXT,
        amount REAL, -- Normalized USD amount
        amount_in_currency REAL,
        currency_code TEXT,
        expense_date TEXT,
        category_local_id INTEGER, -- Link to local category
        recurrence TEXT DEFAULT 'one_time',
        sync_status INTEGER DEFAULT 0
      )
    ''');

    // --- 5. WITHDRAWALS ---
    await db.execute('''
      CREATE TABLE withdrawals (
        local_id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER,
        description TEXT,
        amount REAL,
        amount_in_currency REAL,
        currency_code TEXT,
        withdrawal_date TEXT,
        sync_status INTEGER DEFAULT 0
      )
    ''');

    // --- 6. SALES HEADER ---
    await db.execute('''
      CREATE TABLE sales (
        local_id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER,
        total_price REAL,
        currency_code TEXT,
        rate_to_usd_at_sale REAL,
        employee_id INTEGER,
        created_at TEXT,
        sync_status INTEGER DEFAULT 0
      )
    ''');

    // --- 7. SALE ITEMS ---
    await db.execute('''
      CREATE TABLE sale_items (
        local_id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_local_id INTEGER,
        product_local_id INTEGER,
        quantity INTEGER,
        returned_quantity INTEGER DEFAULT 0,
        price REAL,
        cost_price_at_sale REAL, 
        FOREIGN KEY (sale_local_id) REFERENCES sales (local_id) ON DELETE CASCADE
      )
    ''');
    
    // --- 8. EXCHANGE RATES (Lookup table) ---
    await db.execute('''
      CREATE TABLE exchange_rates (
        currency_code TEXT PRIMARY KEY,
        rate_to_usd REAL
      )
    ''');

       // --- 9. PROFILE (Singleton) ---
    await db.execute('''
      CREATE TABLE profiles (
        id INTEGER PRIMARY KEY, -- We only keep one row (id=1)
        shop_name TEXT,
        address TEXT,
        phone_number TEXT,
        city TEXT,
        has_manager_password INTEGER DEFAULT 0
      )
    ''');
  }
}