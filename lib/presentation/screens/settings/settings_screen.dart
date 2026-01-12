import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hasbni/data/models/exchange_rate_model.dart';
import 'package:hasbni/data/models/profile_model.dart';
import 'package:hasbni/presentation/cubits/profile/profile_cubit.dart';
import 'package:hasbni/presentation/cubits/profile/profile_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
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
        if (state.status == ProfileStatus.loading) {
          return Scaffold(
            appBar: AppBar(title: const Text('الإعدادات')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // Only show this if we really failed to load anything
        if (state.status == ProfileStatus.failure && state.profile == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('الإعدادات')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("فشل تحميل الإعدادات"),
                  const SizedBox(height: 16),
                  ElevatedButton(
                      onPressed: () => context.read<ProfileCubit>().loadProfile(),
                      child: const Text("إعادة المحاولة"))
                ],
              ),
            ),
          );
        }

        return SettingsView(
          profile: state.profile,
          isLoading: state.status == ProfileStatus.loading,
        );
      },
    );
  }
}

class SettingsView extends StatefulWidget {
  final Profile? profile;
  final bool isLoading;
  const SettingsView({super.key, this.profile, required this.isLoading});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _shopNameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;

  late TextEditingController _managerPasswordController;
  late TextEditingController _confirmManagerPasswordController;

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

    _managerPasswordController = TextEditingController();
    _confirmManagerPasswordController = TextEditingController();
  }

  @override
  void didUpdateWidget(covariant SettingsView oldWidget) {
    super.didUpdateWidget(oldWidget);

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
          text: (widget.profile?.exchangeRates
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

      // 1. Set Password
      if (newPassword.isNotEmpty) {
        await profileCubit.setManagerPassword(newPassword);
        
        // --- FIX: Check mounted before using controllers ---
        if (!mounted) return; 
        
        _managerPasswordController.clear();
        _confirmManagerPasswordController.clear();
        FocusScope.of(context).unfocus();
      }

      // 2. Prepare Rates
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

      // 3. Save Settings
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