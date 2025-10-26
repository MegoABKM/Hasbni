// lib/presentation/screens/operations/operations_hub_screen.dart
import 'package:flutter/material.dart';
import 'package:hasbni/presentation/screens/sales/point_of_sale_screen.dart';
import 'package:hasbni/presentation/screens/sales/sales_history_screen.dart';

class OperationsHubScreen extends StatelessWidget {
  const OperationsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('العمليات')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildOperationCard(
              context: context,
              title: 'بيع جديد',
              icon: Icons.point_of_sale,
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PointOfSaleScreen()),
                );
              },
            ),
            _buildOperationCard(
              context: context,
              title: 'إرجاع / استبدال',
              icon: Icons.history, // أيقونة السجل هي الأنسب
              color: Colors.orange,
              onTap: () {
                // Navigate to the Sales History screen to find a sale
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SalesHistoryScreen()),
                );
              },
            ),
            // --- END CORRECTION ---
            // يمكنك إضافة المزيد من البطاقات هنا في المستقبل
          ],
        ),
      ),
    );
  }
}

Widget _buildOperationCard({
  required BuildContext context,
  required String title,
  required IconData icon,
  required Color color,
  required VoidCallback onTap,
}) {
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 50, color: color),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    ),
  );
}
