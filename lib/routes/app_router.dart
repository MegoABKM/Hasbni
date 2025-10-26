// lib/routes/app_router.dart
import 'package:flutter/material.dart';
import 'package:hasbni/presentation/screens/inventory/add_edit_product_screen.dart';
import 'package:hasbni/presentation/screens/inventory/inventory_screen.dart';
import 'package:hasbni/presentation/screens/sales/sales_screen.dart'; // <-- استيراد

class AppRouter {
  static const String inventory = '/inventory';
  static const String addEditProduct = '/add-edit-product';
  static const String sales = '/sales'; // <-- مسار جديد

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case inventory:
        return MaterialPageRoute(builder: (_) => const InventoryScreen());
      case addEditProduct:
        return MaterialPageRoute(builder: (_) => const AddEditProductScreen());
      case sales: // <-- إضافة الحالة
        return MaterialPageRoute(builder: (_) => SalesScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Error: Route not found')),
          ),
        );
    }
  }
}
