import 'package:hasbni/data/models/expense_model.dart';
import 'package:hasbni/data/models/sale_model.dart';
import 'package:hasbni/data/models/withdrawal_model.dart';

enum DiaryType { sale, expense, withdrawal }

class DiaryItem {
  final DateTime date;
  final DiaryType type;
  final double amount; // In USD (or base currency)
  final dynamic originalItem; // Holds the full Sale, Expense, or Withdrawal object

  DiaryItem({
    required this.date,
    required this.type,
    required this.amount,
    required this.originalItem,
  });

  // Helpers for display
  String get title {
    switch (type) {
      case DiaryType.sale:
        return 'عملية بيع #${(originalItem as Sale).id}';
      case DiaryType.expense:
        return (originalItem as Expense).description.isEmpty
            ? 'مصروف'
            : (originalItem as Expense).description;
      case DiaryType.withdrawal:
        return (originalItem as Withdrawal).description?.isEmpty ?? true
            ? 'سحب شخصي'
            : (originalItem as Withdrawal).description!;
    }
  }
}