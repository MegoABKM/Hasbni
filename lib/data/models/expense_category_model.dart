// lib/data/models/expense_category_model.dart
import 'package:equatable/equatable.dart';

class ExpenseCategory extends Equatable {
  final int id;
  final String name;

  const ExpenseCategory({required this.id, required this.name});

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) {
    return ExpenseCategory(id: json['id'], name: json['name']);
  }

  Map<String, dynamic> toJson() {
    return {'name': name};
  }

  @override
  List<Object?> get props => [id, name];
}
