import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:hasbni/data/models/employee_model.dart';
import 'package:hasbni/data/repositories/auth_repository.dart';
import 'package:hasbni/data/repositories/employee_repository.dart';
import 'package:hasbni/presentation/cubits/auth/auth_cubit.dart';
import 'package:hasbni/presentation/cubits/session/session_cubit.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  void _showManagerPasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<SessionCubit>(),
        child: const _ManagerPasswordDialog(),
      ),
    );
  }

  void _showEmployeeSelectionDialog(BuildContext context) {
    final employeeRepo = EmployeeRepository();
    final sessionCubit = context.read<SessionCubit>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return FutureBuilder<List<Employee>>(
          future: employeeRepo.getEmployees(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                content: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return AlertDialog(
                title: const Text('خطأ'),
                content: const Text('فشل تحميل قائمة الموظفين.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('حسناً'),
                  ),
                ],
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return AlertDialog(
                title: const Text('لا يوجد موظفين'),
                content: const Text('لم يقم المدير بإضافة أي موظفين بعد.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('حسناً'),
                  ),
                ],
              );
            }

            Employee? selectedEmployee;
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: const Text('اختر اسمك'),
                  content: DropdownButtonFormField<Employee>(
                    hint: const Text('اختر الموظف'),
                    value: selectedEmployee,
                    isExpanded: true,
                    items: snapshot.data!.map((employee) {
                      return DropdownMenuItem<Employee>(
                        value: employee,
                        child: Text(employee.fullName),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => selectedEmployee = value),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('إلغاء'),
                    ),
                    ElevatedButton(
                      onPressed: selectedEmployee == null
                          ? null
                          : () async {
                              await sessionCubit.setEmployeeRole(
                                selectedEmployee!,
                              );
                              if (dialogContext.mounted) {
                                Navigator.of(dialogContext).pop();
                              }
                            },
                      child: const Text('دخول'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.how_to_reg_outlined,
                  size: 80,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'اختر طريقة الدخول',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'من فضلك حدد دورك للمتابعة',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 48),
                AnimationLimiter(
                  child: Column(
                    children: AnimationConfiguration.toStaggeredList(
                      duration: const Duration(milliseconds: 375),
                      childAnimationBuilder: (widget) => SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(child: widget),
                      ),
                      children: [
                        _RoleSelectionCard(
                          icon: Icons.shield_outlined,
                          title: 'أنا المدير',
                          subtitle: 'الوصول الكامل للنظام',
                          onTap: () => _showManagerPasswordDialog(context),
                        ),
                        const SizedBox(height: 24),
                        _RoleSelectionCard(
                          icon: Icons.person_outline,
                          title: 'أنا موظف',
                          subtitle: 'الدخول إلى نقطة البيع',
                          onTap: () => _showEmployeeSelectionDialog(context),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('تسجيل الخروج'),
                  onPressed: () => context.read<AuthCubit>().signOut(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleSelectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleSelectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface.withOpacity(0.9),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor, width: 0.5),
          ),
          child: Row(
            children: [
              Icon(icon, size: 40, color: theme.colorScheme.primary),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManagerPasswordDialog extends StatefulWidget {
  const _ManagerPasswordDialog();

  @override
  State<_ManagerPasswordDialog> createState() => _ManagerPasswordDialogState();
}

class _ManagerPasswordDialogState extends State<_ManagerPasswordDialog> {
  final _authRepo = AuthRepository();
  final _passwordController = TextEditingController();
  bool _isLoading = true;
  bool _isPasswordSet = false;
  String? _errorText;
  bool _isGuestMode = false;

  @override
  void initState() {
    super.initState();
    // Do NOT call _checkIfPasswordIsSet here directly anymore.
    // We defer it to didChangeDependencies to ensure we have context access
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkContextAndInit();
  }

  Future<void> _checkContextAndInit() async {
    // 1. Check if we are in Guest Mode
    final authState = context.read<AuthCubit>().state;

    // IMPORTANT: Check if the user ID is 0 (Guest Mode ID)
    if (authState.user != null && authState.user!.id == 0) {
      if (mounted) {
        setState(() {
          _isGuestMode = true;
          _isLoading = false;
          _isPasswordSet = false; // Guests don't have passwords
        });
      }
      return; // STOP HERE! Do not proceed to server check.
    }

    // 2. Normal Online Mode - Only run if NOT guest mode
    if (!_isGuestMode && _isLoading) {
       await _checkIfPasswordIsSet();
    }
  }

  Future<void> _checkIfPasswordIsSet() async {
    // If we are already in guest mode, abort
    if(_isGuestMode) return;

    if (!mounted) return;
    try {
      final result = await _authRepo.isManagerPasswordSet();
      if (mounted) setState(() => _isPasswordSet = result);
    } catch (e) {
      // If offline in normal mode, we can't verify password setting.
      if (mounted) setState(() => _errorText = 'فشل الاتصال بالخادم.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleManagerLogin() async {
    final sessionCubit = context.read<SessionCubit>();

    // --- NEW: Immediate success for Guest Mode ---
    if (_isGuestMode) {
      await sessionCubit.setManagerRole();
      if (mounted) Navigator.of(context).pop();
      return;
    }
    // ---------------------------------------------

    if (_isLoading) return;

    if (!_isPasswordSet) {
      await sessionCubit.setManagerRole();
      if (mounted) Navigator.of(context).pop();
      return;
    }

    if (_passwordController.text.isEmpty) {
      setState(() => _errorText = "الرجاء إدخال كلمة المرور");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    try {
      final isValid = await _authRepo.verifyManagerPassword(
        _passwordController.text,
      );
      if (mounted) {
        if (isValid) {
          await sessionCubit.setManagerRole();
          if (mounted) Navigator.of(context).pop();
        } else {
          setState(() => _errorText = 'كلمة المرور غير صحيحة');
        }
      }
    } catch (e) {
      if (mounted) setState(() => _errorText = 'حدث خطأ أثناء التحقق.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AlertDialog(
        content: Center(child: CircularProgressIndicator()),
      );
    }

    // If error and NOT guest mode
    if (_errorText != null && !_isPasswordSet && !_isGuestMode) {
      return AlertDialog(
        title: const Text("خطأ في الاتصال"),
        content: Text(_errorText!),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("إغلاق"),
          ),
        ],
      );
    }

    // If Guest Mode or No Password Set -> Show Info Dialog
    return (_isPasswordSet && !_isGuestMode)
        ? _buildPasswordEntryDialog()
        : _buildFirstTimeInfoDialog();
  }

  Widget _buildFirstTimeInfoDialog() {
    // Customize text for Guest Mode
    final String message = _isGuestMode
        ? 'أنت الآن في وضع التجربة (بدون إنترنت). يمكنك استخدام النظام كمدير، ولكن لن يتم حفظ البيانات على السحابة حتى تسجل الدخول.'
        : 'لم تقم بتعيين كلمة مرور للمدير بعد. يمكنك الدخول مباشرة هذه المرة.\n\nنوصي بالذهاب إلى الإعدادات لتعيين كلمة مرور.';

    return AlertDialog(
      title: const Text('مرحباً بك أيها المدير'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _handleManagerLogin,
          child: const Text('متابعة'),
        ),
      ],
    );
  }

  Widget _buildPasswordEntryDialog() {
    return AlertDialog(
      title: const Text('دخول المدير'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _passwordController,
            obscureText: true,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'كلمة مرور المدير',
              errorText: _errorText,
            ),
            onSubmitted: _isLoading ? null : (_) => _handleManagerLogin(),
          ),
          if (_isLoading) ...[
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleManagerLogin,
          child: const Text('دخول'),
        ),
      ],
    );
  }
}