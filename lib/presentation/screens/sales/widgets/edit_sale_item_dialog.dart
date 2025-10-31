
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hasbni/data/models/sale_model.dart';
import 'package:hasbni/presentation/cubits/sales/sales_cubit.dart';

class EditSaleItemDialog extends StatefulWidget {
  final SaleItem item;
  final String currency;

  
  const EditSaleItemDialog({
    super.key,
    required this.item,
    required this.currency,
  });

  @override
  State<EditSaleItemDialog> createState() => _EditSaleItemDialogState();
}

class _EditSaleItemDialogState extends State<EditSaleItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _quantityController;
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(
      text: widget.item.quantity.toString(),
    );
    _priceController = TextEditingController(
      text: widget.item.sellingPrice.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      
      final salesCubit = context.read<SalesCubit>();

      final newQuantity = int.tryParse(_quantityController.text) ?? 0;
      final newPrice = double.tryParse(_priceController.text) ?? 0.0;

      salesCubit.updatePrice(widget.item.product, newPrice);
      
      salesCubit.updateQuantity(widget.item.product, newQuantity);

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    
    final salesCubit = context.read<SalesCubit>();

    return AlertDialog(
      title: Text('تعديل "${widget.item.product.name}"'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'الكمية',
                hintText: 'المتاح: ${widget.item.product.quantity}',
                prefixIcon: const Icon(Icons.shopping_basket_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'الحقل مطلوب';
                final quantity = int.tryParse(value);
                if (quantity == null || quantity < 0)
                  return 'أدخل رقماً صحيحاً';
                if (quantity > widget.item.product.quantity)
                  return 'الكمية أكبر من المتوفر (${widget.item.product.quantity})';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'سعر البيع للوحدة',
                suffixText: widget.currency,
                hintText:
                    'السعر الأصلي: ${widget.item.product.sellingPrice.toStringAsFixed(2)}',
                prefixIcon: const Icon(Icons.price_change_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'الحقل مطلوب';
                final price = double.tryParse(value);
                if (price == null || price < 0) return 'أدخل سعراً صحيحاً';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            salesCubit.removeFromCart(widget.item.product);
            Navigator.of(context).pop();
          },
          child: const Text(
            'حذف الصنف',
            style: TextStyle(color: Colors.redAccent),
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('حفظ التعديلات')),
      ],
    );
  }
}
