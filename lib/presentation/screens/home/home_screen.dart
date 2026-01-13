import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:hasbni/core/services/sync_service.dart';
import 'package:hasbni/presentation/cubits/auth/auth_cubit.dart';
import 'package:hasbni/presentation/cubits/inventory/inventory_cubit.dart';
import 'package:hasbni/presentation/cubits/profile/profile_cubit.dart';
import 'package:hasbni/presentation/cubits/profile/profile_state.dart';
import 'package:hasbni/presentation/screens/employees/employee_management_screen.dart';
import 'package:hasbni/presentation/screens/expenses/expenses_screen.dart';
import 'package:hasbni/presentation/screens/inventory/inventory_screen.dart';
import 'package:hasbni/presentation/screens/operations/operations_hub_screen.dart';
import 'package:hasbni/presentation/screens/reports/reports_screen.dart';
import 'package:hasbni/presentation/screens/sales/sales_history_screen.dart';
import 'package:hasbni/presentation/screens/settings/settings_screen.dart';
import 'package:hasbni/presentation/screens/withdrawals/withdrawals_screen.dart';
import 'package:hasbni/presentation/widgets/home_list_item_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if we are in Guest Mode
    final authState = context.watch<AuthCubit>().state;
    final isGuest = authState.user?.id == 0;

    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        // --- FIX START ---
        // If we have a profile (even from cache/default), show the UI immediately.
        // Do NOT show spinner if we are simply refreshing in the background.
        // Also, if in Guest Mode, show default title if profile is loading.
        
        final isLoading = state.status == ProfileStatus.loading || state.status == ProfileStatus.initial;
        
        // If we have data, use it. If loading and no data, check guest mode.
        final hasData = state.profile != null;

        String shopName = 'لوحة التحكم';
        if (hasData) {
          shopName = state.profile!.shopName.isNotEmpty ? state.profile!.shopName : shopName;
        } else if (isGuest) {
          shopName = 'متجر تجريبي'; // Immediate title for Guest
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              shopName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'الإعدادات',
                onPressed: () {
                   // Allow settings even if profile is null (SettingsScreen handles it)
                   Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SettingsScreen(),
                      ),
                    );
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout_outlined),
                tooltip: 'تسجيل الخروج',
                onPressed: () {
                  context.read<AuthCubit>().signOut();
                },
              ),
              IconButton(
                icon: const Icon(Icons.sync),
                tooltip: 'مزامنة البيانات',
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('جاري المزامنة...')),
                  );

                  await SyncService().syncEverything();

                  if (context.mounted) {
                    context.read<InventoryCubit>().loadProducts(isRefresh: true);
                    context.read<ProfileCubit>().loadProfile(); 
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تمت المزامنة بنجاح')),
                    );
                  }
                },
              ),
            ],
          ),
          // --- FIX BODY LOGIC ---
          body: (isLoading && !hasData && !isGuest) 
              ? const Center(child: CircularProgressIndicator()) 
              : _buildBody(context, state, isGuest),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ProfileState state, bool isGuest) {
    if (state.status == ProfileStatus.failure && !isGuest) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(state.errorMessage ?? 'فشل تحميل البيانات.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<ProfileCubit>().loadProfile(),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    return _buildMenuList(context);
  }

  Widget _buildMenuList(BuildContext context) {
     // ... (Keep existing code exactly the same)
    final theme = Theme.of(context);

    final List<Map<String, dynamic>> dailyOps = [
      {
        'title': 'نقطة البيع',
        'subtitle': 'تسجيل المبيعات والإرجاع',
        'icon': Icons.point_of_sale_outlined,
        'color': theme.colorScheme.primary,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OperationsHubScreen()),
            ),
      },
      {
        'title': 'المخزون',
        'subtitle': 'إدارة المنتجات والكميات',
        'icon': Icons.inventory_2_outlined,
        'color': Colors.orangeAccent,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<ProfileCubit>(),
                  child: const InventoryScreen(),
                ),
              ),
            ),
      },
    ];

    final List<Map<String, dynamic>> financialManagement = [
      {
        'title': 'التقارير المالية',
        'subtitle': 'متابعة الأرباح والإيرادات',
        'icon': Icons.bar_chart_outlined,
        'color': Colors.greenAccent,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportsScreen()),
            ),
      },
      {
        'title': 'سجل الفواتير',
        'subtitle': 'عرض جميع فواتير المبيعات',
        'icon': Icons.receipt_long_outlined,
        'color': Colors.purpleAccent,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SalesHistoryScreen()),
            ),
      },
      {
        'title': 'المصروفات',
        'subtitle': 'تسجيل النفقات التشغيلية',
        'icon': Icons.money_off_csred_outlined,
        'color': Colors.redAccent,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ExpensesScreen()),
            ),
      },
      {
        'title': 'المسحوبات الشخصية',
        'subtitle': 'تسجيل مسحوبات المالك',
        'icon': Icons.person_remove_outlined,
        'color': Colors.cyan,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WithdrawalsScreen()),
            ),
      },
    ];

    final List<Map<String, dynamic>> systemManagement = [
      {
        'title': 'إدارة الموظفين',
        'subtitle': 'إضافة وتعديل حسابات الموظفين',
        'icon': Icons.people_alt_outlined,
        'color': Colors.indigoAccent,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const EmployeeManagementScreen()),
            ),
      },
    ];

    return AnimationLimiter(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('العمليات اليومية'),
          ..._buildAnimatedList(dailyOps),
          const SizedBox(height: 24),
          _buildSectionHeader('الإدارة والتقارير'),
          ..._buildAnimatedList(financialManagement),
          const SizedBox(height: 24),
          _buildSectionHeader('إدارة النظام'),
          ..._buildAnimatedList(systemManagement),
        ],
      ),
    );
  }

  List<Widget> _buildAnimatedList(List<Map<String, dynamic>> items) {
     // ... (Keep existing code exactly the same)
    return AnimationConfiguration.toStaggeredList(
      duration: const Duration(milliseconds: 375),
      childAnimationBuilder: (widget) => SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(child: widget),
      ),
      children: items
          .map(
            (item) => HomeListItem(
              title: item['title'],
              subtitle: item['subtitle'],
              icon: item['icon'],
              iconColor: item['color'],
              onTap: item['onTap'],
            ),
          )
          .toList(),
    );
  }

  Widget _buildSectionHeader(String title) {
     // ... (Keep existing code exactly the same)
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, right: 8.0, top: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey[500],
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}