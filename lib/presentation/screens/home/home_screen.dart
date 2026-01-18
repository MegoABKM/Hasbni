import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
import 'package:hasbni/presentation/screens/subscription/subscription_screen.dart';
import 'package:hasbni/presentation/screens/withdrawals/withdrawals_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if we are in Guest Mode
    final authState = context.watch<AuthCubit>().state;
    final isGuest = authState.user?.id == 0;

    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        final isLoading = state.status == ProfileStatus.loading ||
            state.status == ProfileStatus.initial;
        final hasData = state.profile != null;

        String shopName = 'لوحة التحكم';
        if (hasData) {
          shopName = state.profile!.shopName.isNotEmpty
              ? state.profile!.shopName
              : shopName;
        } else if (isGuest) {
          shopName = 'متجر تجريبي';
        }

        return Scaffold(
          body: (isLoading && !hasData && !isGuest)
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildSliverAppBar(context, shopName, isGuest),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 16.h),
                            _buildQuickStats(context),
                            SizedBox(height: 24.h),
                            _buildSectionHeader('الوصول السريع'),
                            SizedBox(height: 12.h),
                            _buildQuickAccessGrid(context),
                            SizedBox(height: 24.h),
                            _buildSectionHeader('الإدارة والمالية'),
                            SizedBox(height: 12.h),
                          ],
                        ),
                      ),
                    ),
                    _buildManagementList(context),
                    SliverToBoxAdapter(child: SizedBox(height: 40.h)),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildSliverAppBar(BuildContext context, String title, bool isGuest) {
    return SliverAppBar(
      expandedHeight: 100.h,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 12.h),
        title: Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onBackground,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.diamond_outlined, color: Colors.amber, size: 24.r),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SubscriptionScreen())),
        ),
        IconButton(
          icon: Icon(Icons.settings_outlined, size: 24.r),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SettingsScreen())),
        ),
        if (!isGuest)
          IconButton(
            icon: Icon(Icons.sync, size: 24.r),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('جاري المزامنة...')));
              await SyncService().syncEverything();
              if (context.mounted) {
                context.read<InventoryCubit>().loadProducts(isRefresh: true);
                context.read<ProfileCubit>().loadProfile();
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تمت المزامنة بنجاح')));
              }
            },
          ),
      ],
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    // Increased height from 100.h to 130.h to prevent overflow
    return SizedBox(
      height: 130.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildStatCard(
            context,
            title: 'مبيعات اليوم',
            value: '---',
            icon: Icons.attach_money,
            color: Colors.green,
          ),
          SizedBox(width: 12.w),
          _buildStatCard(
            context,
            title: 'المنتجات',
            value: 'المخزون',
            icon: Icons.inventory_2_outlined,
            color: Colors.blue,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const InventoryScreen())),
          ),
          SizedBox(width: 12.w),
          _buildStatCard(
            context,
            title: 'تنبيهات',
            value: '0',
            icon: Icons.notifications_none,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context,
      {required String title,
      required String value,
      required IconData icon,
      required Color color,
      VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140.w,
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        // Changed to Column with Spacer/Flexible to handle overflow
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24.r),
                Container(
                    width: 6.r,
                    height: 6.r,
                    decoration: BoxDecoration(
                        color: color.withOpacity(0.5), shape: BoxShape.circle)),
              ],
            ),
            const Spacer(), // Pushes content to bottom
            Text(
              value,
              maxLines: 1, // Prevent multi-line overflow
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4.h),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessGrid(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildBigCard(
            context,
            title: 'نقطة البيع',
            subtitle: 'بيع جديد',
            icon: Icons.point_of_sale_rounded,
            color: Theme.of(context).colorScheme.primary,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const OperationsHubScreen())),
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: _buildBigCard(
            context,
            title: 'الفواتير',
            subtitle: 'السجل',
            icon: Icons.receipt_long_rounded,
            color: Colors.purpleAccent,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SalesHistoryScreen())),
          ),
        ),
      ],
    );
  }

  Widget _buildBigCard(BuildContext context,
      {required String title,
      required String subtitle,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          // REMOVED fixed height (was 160.h)
          // Added vertical padding to give it breathing room naturally
          padding: EdgeInsets.symmetric(horizontal: 16.r, vertical: 24.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // Important: shrink to fit content
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 36.r),
              ),
              SizedBox(height: 16.h),
              Text(
                title,
                maxLines: 1,
                style: TextStyle(
                    fontSize: 16.sp, fontWeight: FontWeight.bold, color: color),
              ),
              SizedBox(height: 4.h),
              Text(
                subtitle,
                maxLines: 1,
                style:
                    TextStyle(fontSize: 12.sp, color: color.withOpacity(0.8)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManagementList(BuildContext context) {
    final List<Map<String, dynamic>> menuItems = [
      {
        'title': 'المخزون والمنتجات',
        'subtitle': 'إضافة وتعديل المنتجات',
        'icon': Icons.inventory_2_outlined,
        'color': Colors.orange,
        'onTap': () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const InventoryScreen())),
      },
      {
        'title': 'التقارير المالية',
        'subtitle': 'الأرباح والخسائر',
        'icon': Icons.bar_chart_rounded,
        'color': Colors.blue,
        'onTap': () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const ReportsScreen())),
      },
      {
        'title': 'المصروفات',
        'subtitle': 'تسجيل النفقات',
        'icon': Icons.money_off_rounded,
        'color': Colors.redAccent,
        'onTap': () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const ExpensesScreen())),
      },
      {
        'title': 'المسحوبات الشخصية',
        'subtitle': 'سحب المالك',
        'icon': Icons.person_remove_rounded,
        'color': Colors.teal,
        'onTap': () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const WithdrawalsScreen())),
      },
      {
        'title': 'الموظفين',
        'subtitle': 'إدارة الصلاحيات',
        'icon': Icons.people_alt_rounded,
        'color': Colors.indigo,
        'onTap': () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const EmployeeManagementScreen())),
      },
    ];

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = menuItems[index];
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
            child: AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: _buildListItem(
                    context,
                    title: item['title'],
                    subtitle: item['subtitle'],
                    icon: item['icon'],
                    color: item['color'],
                    onTap: item['onTap'],
                  ),
                ),
              ),
            ),
          );
        },
        childCount: menuItems.length,
      ),
    );
  }

  Widget _buildListItem(BuildContext context,
      {required String title,
      required String subtitle,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16.r),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, color: color, size: 24.r),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 16.sp, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4.h),
                    Text(subtitle,
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 16.r, color: Colors.grey[300]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.bold,
        color: Colors.grey[600],
      ),
    );
  }
}
