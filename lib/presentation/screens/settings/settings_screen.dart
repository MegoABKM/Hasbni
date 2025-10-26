// lib/presentation/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hasbni/data/models/exchange_rate_model.dart';
import 'package:hasbni/data/models/profile_model.dart';
import 'package:hasbni/presentation/cubits/profile/profile_cubit.dart';
import 'package:hasbni/presentation/cubits/profile/profile_state.dart';

// This part is correct and doesn't need changes.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      // We use listenWhen to only show the snackbar once per success/failure message
      // to avoid showing it multiple times on other state changes.
      listenWhen: (previous, current) =>
          previous.successMessage != current.successMessage ||
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      builder: (context, state) {
        // This loading check is correct.
        if (state.profile == null && state.status == ProfileStatus.loading) {
          return Scaffold(
            appBar: AppBar(title: const Text('الإعدادات')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        // Pass the profile and loading status to the stateful view.
        return SettingsView(
          profile: state.profile,
          isLoading: state.status == ProfileStatus.loading,
        );
      },
    );
  }
}

// This is the main view widget
class SettingsView extends StatefulWidget {
  final Profile? profile;
  final bool isLoading;
  const SettingsView({super.key, this.profile, required this.isLoading});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for Shop Info
  late TextEditingController _shopNameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;

  // Controllers for Manager Security
  late TextEditingController _managerPasswordController;
  late TextEditingController _confirmManagerPasswordController;

  // Controllers for Exchange Rates
  final List<String> _availableCurrencies = [
    'LYD',
    'USD',
    'EUR',
    'TND',
    'EGP',
    'SYP',
  ];
  late Map<String, TextEditingController> _rateControllers;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    // Initialize password controllers separately as they are always empty at start.
    _managerPasswordController = TextEditingController();
    _confirmManagerPasswordController = TextEditingController();
  }

  @override
  void didUpdateWidget(covariant SettingsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-initialize if the profile data changes (e.g., after saving)
    if (widget.profile != oldWidget.profile) {
      _initializeControllers();
    }
  }

  void _initializeControllers() {
    _shopNameController = TextEditingController(
      text: widget.profile?.shopName ?? '',
    );
    _addressController = TextEditingController(
      text: widget.profile?.address ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.profile?.phoneNumber ?? '',
    );

    _rateControllers = {
      for (var code in _availableCurrencies)
        code: TextEditingController(
          text:
              (widget.profile?.exchangeRates
                          .firstWhere(
                            (r) => r.currencyCode == code,
                            orElse: () => ExchangeRate(
                              currencyCode: code,
                              rateToUsd: 0.0,
                            ),
                          )
                          .rateToUsd ??
                      0.0)
                  .toString(),
        ),
    };
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _managerPasswordController.dispose();
    _confirmManagerPasswordController.dispose();
    _rateControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _submit() async {
    if (widget.isLoading) return;
    if (_formKey.currentState!.validate()) {
      final profileCubit = context.read<ProfileCubit>();
      final newPassword = _managerPasswordController.text;

      // 1. Handle password saving if a new one is entered
      if (newPassword.isNotEmpty) {
        await profileCubit.setManagerPassword(newPassword);
        _managerPasswordController.clear();
        _confirmManagerPasswordController.clear();
        FocusScope.of(context).unfocus(); // Hide keyboard
      }

      // 2. Handle profile and exchange rate saving
      final existingRates = widget.profile?.exchangeRates ?? [];
      final ratesToUpdate = <ExchangeRate>[];
      _rateControllers.forEach((code, controller) {
        final rate = double.tryParse(controller.text.trim());
        if (code != 'USD' && rate != null && rate > 0) {
          final existingRate = existingRates.firstWhere(
            (r) => r.currencyCode == code,
            orElse: () =>
                const ExchangeRate(id: null, currencyCode: '', rateToUsd: 0),
          );
          ratesToUpdate.add(
            ExchangeRate(
              id: existingRate.id,
              currencyCode: code,
              rateToUsd: rate,
            ),
          );
        }
      });

      final profileData = {
        'shop_name': _shopNameController.text.trim(),
        'address': _addressController.text.trim(),
        'phone_number': _phoneController.text.trim(),
      };

      await profileCubit.saveSettings(
        profileData: profileData,
        rates: ratesToUpdate,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        actions: [
          if (widget.isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.0),
              ),
            ),
          if (!widget.isLoading)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _submit,
              tooltip: 'حفظ التغييرات',
            ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: widget.isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Section 1: Shop Info ---
                Text(
                  'بيانات المتجر',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _shopNameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم المتجر',
                    prefixIcon: Icon(Icons.store),
                  ),
                  validator: (value) =>
                      value!.trim().isEmpty ? 'اسم المتجر مطلوب' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'العنوان (اختياري)',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف (اختياري)',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                ),

                // --- Section 2: Manager Security ---
                const Divider(height: 48),
                Text(
                  'أمان المدير',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'اترك الحقول فارغة إذا كنت لا ترغب في تغيير كلمة المرور الحالية.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _managerPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'كلمة مرور المدير الجديدة',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty && value.length < 4) {
                      return 'كلمة المرور يجب أن تكون 4 أحرف على الأقل';
                    }
                    // This check is important: if confirm password has a value but this is empty, it's an error.
                    if (_confirmManagerPasswordController.text.isNotEmpty &&
                        (value == null || value.isEmpty)) {
                      return 'الرجاء إدخال كلمة المرور هنا أيضاً';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmManagerPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'تأكيد كلمة المرور الجديدة',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if (value != _managerPasswordController.text) {
                      return 'كلمتا المرور غير متطابقتين';
                    }
                    return null;
                  },
                ),

                // --- Section 3: Exchange Rates ---
                const Divider(height: 48),
                Text(
                  'أسعار الصرف',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'أدخل قيمة كل عملة مقابل الدولار الأمريكي (USD).',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                ..._rateControllers.entries.map((entry) {
                  final currencyCode = entry.key;
                  final controller = entry.value;
                  if (currencyCode == 'USD') return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: TextFormField(
                      controller: controller,
                      decoration: InputDecoration(
                        labelText: 'سعر $currencyCode مقابل USD',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return null;
                        if (double.tryParse(value) == null)
                          return 'قيمة غير صالحة';
                        return null;
                      },
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
