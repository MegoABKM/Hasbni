// lib/presentation/screens/home/employee_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hasbni/presentation/cubits/auth/auth_cubit.dart';
import 'package:hasbni/presentation/cubits/session/session_cubit.dart';
import 'package:hasbni/presentation/screens/operations/operations_hub_screen.dart';

class EmployeeHomeScreen extends StatelessWidget {
  const EmployeeHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final employeeName =
        context.watch<SessionCubit>().state.currentEmployee?.fullName ?? 'موظف';

    return Scaffold(
      appBar: AppBar(
        title: Text('أهلاً بك، $employeeName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل الخروج',
            onPressed: () => context.read<AuthCubit>().signOut(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // This is the only option for the employee
              Card(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OperationsHubScreen(),
                      ),
                    );
                  },
                  child: const SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.point_of_sale_outlined,
                          size: 60,
                          color: Colors.tealAccent,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'العمليات (بيع / إرجاع)',
                          style: TextStyle(fontSize: 22),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
