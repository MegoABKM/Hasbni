// lib/presentation/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hasbni/presentation/cubits/auth/auth_cubit.dart';
import 'package:hasbni/presentation/cubits/auth/auth_state.dart';
import 'package:hasbni/presentation/screens/auth/register_screen.dart';

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

    return Scaffold(
      body: Container(
        // Add a gradient background
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.scaffoldBackgroundColor, theme.colorScheme.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state.status == AuthStatus.failure) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage ?? 'حدث خطأ'),
                    backgroundColor: theme.colorScheme.error,
                  ),
                );
            }
          },
          builder: (context, state) {
            final isLoading = state.status == AuthStatus.loading;
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  // Wrap form in a styled card
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Add an icon for branding
                        Icon(
                          Icons.storefront_outlined,
                          size: 80,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'تسجيل الدخول إلى حاسبني',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'البريد الإلكتروني',
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => (v == null || !v.contains('@'))
                              ? 'الرجاء إدخال بريد إلكتروني صحيح'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'كلمة المرور',
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: theme.colorScheme.primary,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
                          obscureText: !_isPasswordVisible,
                          validator: (v) => (v == null || v.length < 6)
                              ? 'كلمة المرور يجب أن تكون 6 أحرف على الأقل'
                              : null,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          style: theme.elevatedButtonTheme.style?.copyWith(
                            padding: MaterialStateProperty.all(
                              const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                          onPressed: isLoading ? null : _submit,
                          child: isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : const Text('دخــــول'),
                        ),
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                ),
                          child: Text(
                            'ليس لديك حساب؟ إنشاء حساب جديد',
                            style: TextStyle(color: theme.colorScheme.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
