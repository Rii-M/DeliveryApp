import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

import 'null_database.dart';

class DatabaseService {
  static Database? _database;

  Database get db => _database!;

  Future<void> initialize() async {
    if (_database != null) return;

    if (kIsWeb) {
      _database = NullDatabase();
      return;
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = p.join(dir.path, 'sarishma_delivery.db');

      _database = await openDatabase(
        path,
        version: 23,
        onCreate: _createTables,
        onUpgrade: _onUpgrade,
      );
    } catch (_) {
      _database = NullDatabase();
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 5) {
      await db.execute('DROP TABLE IF EXISTS sync_queue');
      await db.execute('DROP TABLE IF EXISTS estimate_item');
      await db.execute('DROP TABLE IF EXISTS estimate');
      await db.execute('DROP TABLE IF EXISTS delivery_item');
      await db.execute('DROP TABLE IF EXISTS delivery');
      await db.execute('DROP TABLE IF EXISTS product');
      await db.execute('DROP TABLE IF EXISTS category');
      await db.execute('DROP TABLE IF EXISTS customer');
      await db.execute('DROP TABLE IF EXISTS driver');
      await db.execute('DROP TABLE IF EXISTS driver_stock');
      await db.execute('DROP TABLE IF EXISTS sales_return');
      await _createTables(db, newVersion);
      return;
    }

    if (oldVersion < 6) {
      try {
        await db.execute(
          'ALTER TABLE product ADD COLUMN sold_quantity REAL DEFAULT 0',
        );
      } catch (_) {}
    }

    if (oldVersion < 7) {
      try {
        await db.execute('ALTER TABLE delivery ADD COLUMN payment_mode TEXT');
      } catch (_) {}
      await db.execute('''
        CREATE TABLE IF NOT EXISTS payment_mode (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          server_id TEXT NOT NULL UNIQUE,
          name TEXT NOT NULL,
          temp_id INTEGER NOT NULL
        )
      ''');
    }

    if (oldVersion < 8) {
      try {
        await db.execute(
          'ALTER TABLE estimate_item ADD COLUMN discount_amount REAL DEFAULT 0',
        );
      } catch (_) {}
    }

    if (oldVersion < 9) {
      try {
        await db.execute(
          'ALTER TABLE product ADD COLUMN taxable INTEGER DEFAULT 0',
        );
      } catch (_) {}
      await db.execute('DROP TABLE IF EXISTS sales_return_item');
      await db.execute('DROP TABLE IF EXISTS sales_return');
      await db.execute('''
        CREATE TABLE sales_return (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          server_id TEXT,
          customer_id TEXT NOT NULL,
          reason TEXT,
          remarks TEXT,
          created_date TEXT NOT NULL,
          is_synced INTEGER DEFAULT 0,
          discount_type TEXT,
          discount_value REAL DEFAULT 0,
          discount_amount REAL DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE TABLE sales_return_item (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sales_return_id INTEGER NOT NULL,
          product_id TEXT NOT NULL,
          product_name TEXT NOT NULL,
          quantity REAL NOT NULL,
          rate REAL NOT NULL DEFAULT 0,
          unit_id TEXT,
          unit TEXT,
          discount_type TEXT,
          discount_value REAL DEFAULT 0,
          discount_amount REAL DEFAULT 0,
          FOREIGN KEY (sales_return_id) REFERENCES sales_return(id)
        )
      ''');
    }

    if (oldVersion < 10) {
      try {
        await db.execute(
          'ALTER TABLE sales_return ADD COLUMN discount_type TEXT',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE sales_return ADD COLUMN discount_value REAL DEFAULT 0',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE sales_return ADD COLUMN discount_amount REAL DEFAULT 0',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE sales_return_item ADD COLUMN discount_type TEXT',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE sales_return_item ADD COLUMN discount_value REAL DEFAULT 0',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE sales_return_item ADD COLUMN discount_amount REAL DEFAULT 0',
        );
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE product ADD COLUMN chalan_number TEXT');
      } catch (_) {}
    }

    if (oldVersion < 11) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS all_product (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          server_id TEXT NOT NULL UNIQUE,
          code TEXT,
          category_id TEXT NOT NULL,
          name TEXT NOT NULL,
          japanese_name TEXT,
          unit_id TEXT,
          unit TEXT,
          unit_price TEXT,
          image_url TEXT
        )
      ''');
    }

    if (oldVersion < 12) {
      try {
        await db.execute(
          'ALTER TABLE all_product ADD COLUMN unit_price REAL DEFAULT 0',
        );
      } catch (_) {}
    }

    if (oldVersion < 13) {
      // Final schema fix: ensure all_product has correct columns (REAL unit_price)
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS all_product_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            server_id TEXT NOT NULL UNIQUE,
            code TEXT,
            category_id TEXT NOT NULL,
            name TEXT NOT NULL,
            japanese_name TEXT,
            unit_id TEXT,
            unit TEXT,
            unit_price REAL DEFAULT 0,
            image_url TEXT
          )
        ''');
        await db.execute('''
          INSERT INTO all_product_new (id, server_id, code, category_id, name, japanese_name, unit_id, unit, unit_price, image_url)
          SELECT id, server_id, code, category_id, name, japanese_name, unit_id, unit, 
                 CAST(unit_price AS REAL), image_url
          FROM all_product
        ''');
        await db.execute('DROP TABLE all_product');
        await db.execute('ALTER TABLE all_product_new RENAME TO all_product');
      } catch (_) {}
    }

    if (oldVersion < 15) {
      try {
        await db.execute('ALTER TABLE product ADD COLUMN units_json TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE all_product ADD COLUMN units_json TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE delivery_item ADD COLUMN unit_id TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE delivery_item ADD COLUMN unit TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE estimate_item ADD COLUMN unit_id TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE estimate_item ADD COLUMN unit_name TEXT');
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE sales_return ADD COLUMN payment_mode TEXT',
        );
      } catch (_) {}
    }
    if (oldVersion < 16) {
      try {
        await db.execute(
          'ALTER TABLE sales_return ADD COLUMN payment_entries TEXT',
        );
      } catch (_) {}
    }
    if (oldVersion < 17) {
      try {
        await db.execute(
          'ALTER TABLE sales_return_item ADD COLUMN taxable INTEGER DEFAULT 0',
        );
      } catch (_) {}
    }
    if (oldVersion < 18) {
      try {
        await db.execute(
          'ALTER TABLE all_product ADD COLUMN taxable INTEGER DEFAULT 0',
        );
      } catch (_) {}
    }
    if (oldVersion < 19) {
    try {
      await db.execute(
        'ALTER TABLE estimate ADD COLUMN payment_entries TEXT',
      );
    } catch (_) {}
  }
    if (oldVersion < 20) {
      try {
        await db.execute('ALTER TABLE customer ADD COLUMN email TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE customer ADD COLUMN pan TEXT');
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE customer ADD COLUMN discount_group_id TEXT',
        );
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE customer ADD COLUMN record_id TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE customer ADD COLUMN meta_data TEXT');
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE customer ADD COLUMN is_active INTEGER DEFAULT 1',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE customer ADD COLUMN is_allow_credit INTEGER DEFAULT 1',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE customer ADD COLUMN is_synced INTEGER DEFAULT 1',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE customer ADD COLUMN pending_action TEXT',
        );
      } catch (_) {}
    }
    if (oldVersion < 21) {
      try {
        await db.execute(
          'ALTER TABLE sync_queue ADD COLUMN error_message TEXT',
        );
      } catch (_) {}
    }
    if (oldVersion < 22) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS customer_discount_group (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          server_id TEXT NOT NULL UNIQUE,
          record_id TEXT,
          name TEXT NOT NULL,
          discount_percent REAL DEFAULT 0,
          is_active INTEGER DEFAULT 1
        )
      ''');
    }
    if (oldVersion < 23) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS rejected_customer_log (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          phone TEXT,
          reason TEXT,
          created_date TEXT NOT NULL
        )
      ''');
    }
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE driver (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        assigned_category_ids TEXT DEFAULT '[]',
        assigned_product_ids TEXT DEFAULT '[]'
      )
    ''');

    await db.execute('''
      CREATE TABLE customer (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        email TEXT,
        pan TEXT,
        discount_group_id TEXT,
        record_id TEXT,
        meta_data TEXT,
        is_active INTEGER DEFAULT 1,
        is_allow_credit INTEGER DEFAULT 1,
        is_synced INTEGER DEFAULT 1,
        pending_action TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE category (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        japanese_name TEXT,
        description TEXT,
        icon TEXT,
        image_url TEXT,
        image_list TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE product (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id TEXT NOT NULL UNIQUE,
        category_id TEXT NOT NULL,
        name TEXT NOT NULL,
        japanese_name TEXT,
        unit_price REAL NOT NULL,
        stock REAL DEFAULT 0,
        sold_quantity REAL DEFAULT 0,
        unit_id TEXT,
        unit TEXT,
        image_url TEXT,
        product_images TEXT,
        description TEXT,
        taxable INTEGER DEFAULT 0,
        chalan_number TEXT,
        units_json TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE driver_stock (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id TEXT NOT NULL UNIQUE,
        assigned_quantity REAL NOT NULL,
        delivered_quantity REAL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE delivery (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id TEXT,
        customer_id TEXT NOT NULL,
        created_date TEXT NOT NULL,
        payment_mode TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE delivery_item (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        delivery_id INTEGER NOT NULL,
        product_id TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit_price REAL NOT NULL DEFAULT 0,
        unit_id TEXT,
        unit TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE estimate (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id TEXT,
        delivery_id INTEGER NOT NULL,
        gross_total REAL NOT NULL DEFAULT 0,
        estimated_total REAL NOT NULL,
        discount_type TEXT,
        discount_value REAL DEFAULT 0,
        discount_amount REAL DEFAULT 0,
        payment_mode TEXT,
        paid_amount REAL DEFAULT 0,
        remarks TEXT,
        created_date TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0,
        payment_entries TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE estimate_item (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        estimate_id INTEGER NOT NULL,
        product_id TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit_price REAL NOT NULL,
        line_total REAL NOT NULL,
        discount_amount REAL DEFAULT 0,
        unit_id TEXT,
        unit_name TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE sales_return (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id TEXT,
        customer_id TEXT NOT NULL,
        reason TEXT,
        remarks TEXT,
        created_date TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0,
          discount_type TEXT,
          discount_value REAL DEFAULT 0,
          discount_amount REAL DEFAULT 0,
          payment_mode TEXT,
          payment_entries TEXT
        )
      ''');

    await db.execute('''
        CREATE TABLE sales_return_item (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sales_return_id INTEGER NOT NULL,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        quantity REAL NOT NULL,
        rate REAL NOT NULL DEFAULT 0,
        unit_id TEXT,
        unit TEXT,
        discount_type TEXT,
        discount_value REAL DEFAULT 0,
        discount_amount REAL DEFAULT 0,
        taxable INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type TEXT NOT NULL,
        entity_id INTEGER NOT NULL,
        status TEXT NOT NULL,
        created_date TEXT NOT NULL,
        error_message TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE payment_mode (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        temp_id INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE all_product (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id TEXT NOT NULL UNIQUE,
        code TEXT,
        category_id TEXT NOT NULL,
        name TEXT NOT NULL,
        japanese_name TEXT,
        unit_id TEXT,
        unit TEXT,
        unit_price REAL DEFAULT 0,
        image_url TEXT,
        units_json TEXT,
        taxable INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE customer_discount_group (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id TEXT NOT NULL UNIQUE,
        record_id TEXT,
        name TEXT NOT NULL,
        discount_percent REAL DEFAULT 0,
        is_active INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE rejected_customer_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        reason TEXT,
        created_date TEXT NOT NULL
      )
    ''');
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
