import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hasbni/presentation/cubits/auth/auth_cubit.dart';
import 'package:hasbni/presentation/cubits/auth/auth_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().signUp(
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
          // Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF121212),
                  const Color(0xFF1E1E1E),
                  primaryColor.withOpacity(0.1),
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24.r),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Text(
                        'حساب جديد',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: BlocConsumer<AuthCubit, AuthState>(
                    listener: (context, state) {
                      if (state.status == AuthStatus.authenticated) {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      }
                      if (state.status == AuthStatus.failure) {
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Text(state.errorMessage ?? 'حدث خطأ', style: TextStyle(fontSize: 14.sp)),
                              backgroundColor: theme.colorScheme.error,
                              behavior: SnackBarBehavior.floating,
                              margin: EdgeInsets.all(16.r),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                            ),
                          );
                      }
                    },
                    builder: (context, state) {
                      final isLoading = state.status == AuthStatus.loading;
                      return Center(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Icon
                              Container(
                                padding: EdgeInsets.all(24.r),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.person_add_alt_1_rounded,
                                  size: 50.r,
                                  color: primaryColor,
                                ),
                              ),
                              SizedBox(height: 24.h),
                              
                              Text(
                                'انضم إلى عائلة حاسبني',
                                style: TextStyle(
                                  fontSize: 26.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'أنشئ حساباً لإدارة متجرك بسهولة وأمان',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  color: Colors.grey[400],
                                ),
                              ),
                              SizedBox(height: 40.h),

                              Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    _buildTextField(
                                      context,
                                      controller: _emailController,
                                      label: 'البريد الإلكتروني',
                                      icon: Icons.email_outlined,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (v) => (v == null || !v.contains('@')) ? 'بريد إلكتروني غير صالح' : null,
                                    ),
                                    SizedBox(height: 16.h),
                                    _buildTextField(
                                      context,
                                      controller: _passwordController,
                                      label: 'كلمة المرور',
                                      icon: Icons.lock_outline,
                                      isPassword: true,
                                      isVisible: _isPasswordVisible,
                                      onVisibilityToggle: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                                      validator: (v) => (v == null || v.length < 6) ? 'كلمة المرور قصيرة جداً (6 أحرف)' : null,
                                    ),
                                    SizedBox(height: 16.h),
                                    _buildTextField(
                                      context,
                                      controller: _confirmPasswordController,
                                      label: 'تأكيد كلمة المرور',
                                      icon: Icons.check_circle_outline,
                                      isPassword: true,
                                      isVisible: _isPasswordVisible, // Share visibility toggle
                                      validator: (v) => (v != _passwordController.text) ? 'كلمتا المرور غير متطابقتين' : null,
                                    ),
                                    SizedBox(height: 40.h),

                                    SizedBox(
                                      width: double.infinity,
                                      height: 56.h,
                                      child: ElevatedButton(
                                        onPressed: isLoading ? null : _submit,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryColor,
                                          foregroundColor: Colors.black,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16.r),
                                          ),
                                        ),
                                        child: isLoading
                                            ? SizedBox(
                                                height: 24.r,
                                                width: 24.r,
                                                child: const CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
                                              )
                                            : Text(
                                                'إنشاء الحساب',
                                                style: TextStyle(
                                                  fontSize: 18.sp,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 24.h),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'لديك حساب بالفعل؟',
                                    style: TextStyle(color: Colors.grey[400], fontSize: 14.sp),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(
                                      'تسجيل الدخول',
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20.h),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
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
        suffixIcon: isPassword && onVisibilityToggle != null
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
        ),
      ),
    );
  }
}