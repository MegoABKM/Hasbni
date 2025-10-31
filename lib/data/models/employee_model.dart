
import 'package:equatable/equatable.dart';

class Employee extends Equatable {
  final int id;
  final String fullName;

  const Employee({required this.id, required this.fullName});

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(id: json['id'], fullName: json['full_name']);
  }

  Map<String, dynamic> toJson() {
    return {'full_name': fullName};
  }

  @override
  List<Object?> get props => [id, fullName];
}
