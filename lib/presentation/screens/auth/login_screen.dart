import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hasbni/presentation/cubits/auth/auth_cubit.dart';
import 'package:hasbni/presentation/cubits/auth/auth_state.dart';
import 'package:hasbni/presentation/screens/auth/register_screen.dart';
import 'package:hasbni/presentation/screens/subscription/subscription_screen.dart';
import 'package:package_info_plus/package_info_plus.dart'; // Import this

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().signIn(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF121212),
                  const Color(0xFF1E1E1E),
                  primaryColor.withOpacity(0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          BlocConsumer<AuthCubit, AuthState>(
            listener: (context, state) {
              if (state.status == AuthStatus.failure) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(
                        state.errorMessage ?? 'حدث خطأ',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp),
                      ),
                      backgroundColor: theme.colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r)),
                    ),
                  );
              }
            },
            builder: (context, state) {
              final isLoading = state.status == AuthStatus.loading;
              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 40.h),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ... [Logo, Welcome Text, Form Container code remains same] ...
                      // (I am omitting the top part for brevity, assume it is here)
                      
                      // For context, this is where the Logo starts:
                      Container(
                        padding: EdgeInsets.all(20.r),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryColor.withOpacity(0.1),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.2),
                              blurRadius: 20.r,
                              spreadRadius: 5.r,
                            )
                          ],
                        ),
                        child: Icon(Icons.storefront_rounded, size: 60.r, color: primaryColor),
                      ),
                      SizedBox(height: 32.h),

                      Text(
                        'أهلاً بك مجدداً',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 28.sp,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'قم بتسجيل الدخول للمتابعة',
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[400], fontSize: 16.sp),
                      ),
                      SizedBox(height: 40.h),

                      // Form Container
                      Container(
                        padding: EdgeInsets.all(24.r),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E).withOpacity(0.7),
                          borderRadius: BorderRadius.circular(24.r),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                          boxShadow: [
                             BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15.r, offset: Offset(0, 10.h)),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildTextField(
                                controller: _emailController,
                                label: 'البريد الإلكتروني',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) => (v == null || !v.contains('@')) ? 'بريد إلكتروني غير صالح' : null,
                              ),
                              SizedBox(height: 16.h),
                              _buildTextField(
                                controller: _passwordController,
                                label: 'كلمة المرور',
                                icon: Icons.lock_outline,
                                isPassword: true,
                                isVisible: _isPasswordVisible,
                                onVisibilityToggle: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                                validator: (v) => (v == null || v.length < 6) ? 'كلمة المرور قصيرة جداً' : null,
                              ),
                              SizedBox(height: 32.h),
                              SizedBox(
                                width: double.infinity,
                                height: 56.h,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.black,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                                  ),
                                  child: isLoading
                                      ? SizedBox(height: 24.r, width: 24.r, child: const CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black))
                                      : Text('تسجيل الدخول', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 24.h),

                      // Register Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('ليس لديك حساب؟', style: TextStyle(color: Colors.grey[400], fontSize: 14.sp)),
                          TextButton(
                            onPressed: isLoading ? null : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
                            child: Text('إنشاء حساب جديد', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14.sp)),
                          ),
                        ],
                      ),

                      // Guest & Plans Row
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => context.read<AuthCubit>().enterGuestMode(),
                                icon: Icon(Icons.wifi_off_rounded, size: 18.r, color: Colors.grey),
                                label: Text('تجربة\nبدون نت', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 11.sp, height: 1.2)),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
                                  side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFD4AF37), Color(0xFFFFD700)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16.r),
                                  boxShadow: [BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen())),
                                  icon: Icon(Icons.diamond_outlined, color: Colors.black, size: 18.r),
                                  label: Text('خطط\nالأسعار', textAlign: TextAlign.center, style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12.sp, height: 1.2)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: EdgeInsets.symmetric(vertical: 12.h),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // --- APP VERSION (New) ---
                      SizedBox(height: 16.h),
                      FutureBuilder<PackageInfo>(
                        future: PackageInfo.fromPlatform(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Text(
                              'الإصدار ${snapshot.data!.version}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12.sp,
                                fontFamily: 'Cairo', // Ensure number font matches
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      SizedBox(height: 16.h), // Bottom padding
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onVisibilityToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !isVisible,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 16.sp, color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 14.sp, color: Colors.grey[400]),
        prefixIcon: Icon(icon, size: 22.r, color: Colors.grey[400]),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                  size: 22.r,
                  color: Colors.grey,
                ),
                onPressed: onVisibilityToggle,
              )
            : null,
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        contentPadding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 16.w),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: const BorderSide(color: Colors.transparent)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide(color: Colors.redAccent.withOpacity(0.5))),
      ),
    );
  }
}