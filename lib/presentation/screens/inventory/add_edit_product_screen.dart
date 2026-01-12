import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hasbni/core/services/sound_service.dart';
import 'package:hasbni/data/models/product_model.dart';
import 'package:hasbni/presentation/cubits/inventory/inventory_cubit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class AddEditProductScreen extends StatefulWidget {
  final Product? product;
  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _barcodeController;
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _costPriceController;
  late TextEditingController _sellingPriceController;

  bool get _isEditing => widget.product != null;
 bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    _barcodeController = TextEditingController(
      text: widget.product?.barcode ?? '',
    );
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _quantityController = TextEditingController(
      text: widget.product?.quantity.toString() ?? '',
    );
    _costPriceController = TextEditingController(
      text: widget.product?.costPrice.toString() ?? '',
    );
    _sellingPriceController = TextEditingController(
      text: widget.product?.sellingPrice.toString() ?? '',
    );
  }

  Future<void> _scanBarcode() async {
    final barcodeValue = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );
    if (barcodeValue != null && mounted) {
      setState(() {
        _barcodeController.text = barcodeValue;
      });
    }
  }

   void _submitForm() async { // Make async
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true); // Disable button

      final productData = {
        'name': _nameController.text,
        'barcode': _barcodeController.text.isEmpty ? null : _barcodeController.text,
        'quantity': int.parse(_quantityController.text),
        'cost_price': double.parse(_costPriceController.text),
        'selling_price': double.parse(_sellingPriceController.text),
      };

      try {
        if (_isEditing) {
          // Use localId for updates
          await context.read<InventoryCubit>().updateProduct(
                widget.product!.localId!,
                productData,
              );
        } else {
          // Await the add operation
          await context.read<InventoryCubit>().addProduct(productData);
        }

        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم الحفظ بنجاح'), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Close screen AFTER save
        
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
           );
           setState(() => _isLoading = false);
        }
      }
    }
  }
  @override
  void dispose() {
    _barcodeController.dispose();
    _nameController.dispose();
    _quantityController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'تعديل المنتج' : 'إضافة منتج جديد'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'اسم المنتج'),
                validator: (value) => value!.isEmpty ? 'الحقل مطلوب' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _barcodeController,
                decoration: InputDecoration(
                  labelText: 'الباركود (اختياري)',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: _scanBarcode,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(labelText: 'الكمية'),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value!.isEmpty ? 'الحقل مطلوب' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _costPriceController,
                      decoration: const InputDecoration(
                        labelText: 'سعر التكلفة (USD)', // Explicit Label
                        suffixText: '\$', // Dollar sign
                        hintText: 'مثلاً: 10.5',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'الحقل مطلوب' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sellingPriceController,
                decoration: const InputDecoration(
                  labelText: 'سعر البيع (USD)', // Explicit Label
                  suffixText: '\$', // Dollar sign
                  hintText: 'مثلاً: 15.0',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) => value!.isEmpty ? 'الحقل مطلوب' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                 onPressed: _isLoading ? null : _submitForm,
                icon: const Icon(Icons.save),
                label: Text(_isEditing ? 'حفظ التعديلات' : 'حفظ المنتج'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ... BarcodeScannerScreen class remains the same ...
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _isFlashOn = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? barcodeValue = barcodes.first.rawValue;
      if (barcodeValue != null && mounted) {
        SoundService().playBeep();
        _scannerController.stop();
        Navigator.of(context).pop(barcodeValue);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('امسح الباركود')),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleBarcode,
          ),
          
          Container(
            width: MediaQuery.of(context).size.width * 0.7,
            height: MediaQuery.of(context).size.width * 0.4,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.black.withOpacity(0.4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: () {
                      _scannerController.toggleTorch();
                      setState(() {
                        _isFlashOn = !_isFlashOn;
                      });
                    },
                    icon: Icon(
                      _isFlashOn ? Icons.flash_on : Icons.flash_off,
                      color: Colors.white,
                    ),
                    iconSize: 32,
                    tooltip: 'تشغيل/إيقاف الفلاش',
                  ),
                  IconButton(
                    onPressed: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.gallery,
                      );

                      if (image != null) {
                        SoundService().playBeep();
                        if (await _scannerController.analyzeImage(image.path)) {
                          
                          print('Barcode found in image!');
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'لم يتم العثور على باركود في الصورة.',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                    icon: const Icon(Icons.image, color: Colors.white),
                    iconSize: 32,
                    tooltip: 'اختيار من المعرض',
                  ),
                  IconButton(
                    onPressed: () => _scannerController.switchCamera(),
                    icon: const Icon(
                      Icons.flip_camera_ios,
                      color: Colors.white,
                    ),
                    iconSize: 32,
                    tooltip: 'تبديل الكاميرا',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}