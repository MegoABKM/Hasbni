import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('باقات الاشتراك', style: TextStyle(fontSize: 20.sp)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Column(
          children: [
            Text(
              'اختر الباقة المناسبة لمتجرك',
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              'يمكنك الترقية أو الإلغاء في أي وقت',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),

            // Tier 1: Free
            _buildPlanCard(
              context,
              title: 'مجاني',
              price: '0',
              currency: 'USD',
              features: [
                'حتى 50 منتج',
                'موظف واحد (المالك)',
                'نسخ احتياطي محلي فقط',
                'تقارير يومية بسيطة',
              ],
              color: Colors.grey,
              buttonText: 'الخطة الحالية',
              isCurrent: true,
            ),
            SizedBox(height: 20.h),

            // Tier 2: Pro
            _buildPlanCard(
              context,
              title: 'برو (Pro)',
              price: '10',
              currency: 'USD / شهر',
              features: [
                'عدد منتجات غير محدود',
                'مزامنة سحابية (Cloud Sync)',
                'حتى 3 موظفين',
                'تقارير شاملة (شهري/سنوي)',
                'تخصيص الفواتير (PDF)',
              ],
              color: theme.colorScheme.primary,
              isRecommended: true,
              buttonText: 'اشترك الآن',
              onTap: () {
                // TODO: Implement Payment Logic
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('سيتم تفعيل الدفع قريباً!')),
                );
              },
            ),
            SizedBox(height: 20.h),

            // Tier 3: Enterprise
            _buildPlanCard(
              context,
              title: 'المؤسسات',
              price: '30+',
              currency: 'USD / شهر',
              features: [
                'إدارة فروع متعددة',
                'نقل المخزون بين الفروع',
                'تحليلات متقدمة',
                'دعم فني مخصص',
              ],
              color: Colors.purpleAccent,
              buttonText: 'تواصل معنا',
              onTap: () {
                 // TODO: Contact Sales
              },
            ),
             SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String title,
    required String price,
    required String currency,
    required List<String> features,
    required Color color,
    String buttonText = 'اشترك',
    bool isRecommended = false,
    bool isCurrent = false,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(24.r),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20.r),
            border: isRecommended
                ? Border.all(color: color, width: 2)
                : Border.all(color: Colors.grey.withOpacity(0.2)),
            boxShadow: [
              if (isRecommended)
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    price,
                    style: TextStyle(
                      fontSize: 40.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    currency,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              ...features.map((feature) => Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: color, size: 20.r),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            feature,
                            style: TextStyle(fontSize: 14.sp),
                          ),
                        ),
                      ],
                    ),
                  )),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isCurrent ? null : onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCurrent ? Colors.grey.withOpacity(0.2) : color,
                    foregroundColor: isCurrent ? Colors.grey : Colors.black, // Assuming dark theme text color
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    buttonText,
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isRecommended)
          Positioned(
            top: -12.h,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  'الأكثر شيوعاً',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}