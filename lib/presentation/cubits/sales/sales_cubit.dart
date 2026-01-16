import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hasbni/data/models/exchange_rate_model.dart';
import 'package:hasbni/data/models/product_model.dart';
import 'package:hasbni/data/models/sale_model.dart';
import 'package:hasbni/data/repositories/sales_repository.dart';
import 'package:hasbni/presentation/cubits/sales/sales_state.dart';
import 'package:hasbni/presentation/cubits/session/session_cubit.dart';

class SalesCubit extends Cubit<SalesState> {
  final SalesRepository _salesRepository;
  final SessionCubit sessionCubit;
  SalesCubit({required this.sessionCubit})
    : _salesRepository = SalesRepository(),
      super(const SalesState());

  void addProductToCart(Product product) {
    final List<SaleItem> updatedCart = List.from(state.cart);
    
    // --- FIX: Use localId instead of id ---
    final index = updatedCart.indexWhere(
      (item) => item.product.localId == product.localId,
    );

    final currentQuantityInCart = (index != -1)
        ? updatedCart[index].quantity
        : 0;
    
    if (currentQuantityInCart >= product.quantity) {
      emit(
        state.copyWith(
          status: SalesStatus.failure,
          errorMessage: 'لا توجد كمية إضافية من "${product.name}" في المخزون.',
        ),
      );
      // Reset status after error
      Future.delayed(
        const Duration(seconds: 2),
        () => emit(state.copyWith(status: SalesStatus.initial)),
      );
      return;
    }

    if (index != -1) {
      updatedCart[index].quantity++;
    } else {
      updatedCart.add(SaleItem(product: product));
    }
    _recalculateAndEmit(updatedCart);
  }

  
  void updatePrice(Product product, double newPrice) {
    final List<SaleItem> updatedCart = List.from(state.cart);
    
    // --- FIX: Use localId instead of id ---
    final index = updatedCart.indexWhere(
      (item) => item.product.localId == product.localId,
    );

    if (index != -1) {
      if (newPrice >= 0) {
        updatedCart[index].sellingPrice = newPrice;
      }
    }
    _recalculateAndEmit(updatedCart);
  }

  void updateQuantity(Product product, int quantity) {
    final List<SaleItem> updatedCart = List.from(state.cart);
    
    // --- FIX: Use localId instead of id ---
    final index = updatedCart.indexWhere(
      (item) => item.product.localId == product.localId,
    );

    if (index != -1) {
      if (quantity > 0) {
        if (quantity <= updatedCart[index].product.quantity) {
          updatedCart[index].quantity = quantity;
        } else {
          updatedCart[index].quantity = updatedCart[index].product.quantity;
          emit(
            state.copyWith(
              status: SalesStatus.failure,
              errorMessage: 'الكمية المطلوبة أكبر من المتوفر في المخزون.',
            ),
          );
          Future.delayed(
            const Duration(seconds: 2),
            () => emit(state.copyWith(status: SalesStatus.initial)),
          );
        }
      } else {
        // If quantity is 0, remove item
        updatedCart.removeAt(index);
      }
    }
    _recalculateAndEmit(updatedCart);
  }

  void removeFromCart(Product product) {
    final List<SaleItem> updatedCart = List.from(state.cart);
    
    // --- FIX: Use localId instead of id ---
    updatedCart.removeWhere((item) => item.product.localId == product.localId);
    
    _recalculateAndEmit(updatedCart);
  }

  void clearCart() {
    emit(const SalesState(status: SalesStatus.initial));
  }

  Future<void> completeSale({
    required String currencyCode,
    required List<ExchangeRate> rates,
  }) async {
    if (state.cart.isEmpty) return;
    emit(state.copyWith(status: SalesStatus.loading));
    try {
      double rateToUsdAtSale = 1.0;
      if (currencyCode != 'USD') {
        rateToUsdAtSale = rates
            .firstWhere((r) => r.currencyCode == currencyCode)
            .rateToUsd;
      }

      
      final employeeId = sessionCubit.state.currentEmployee?.id;

      final saleId = await _salesRepository.createSale(
        items: state.cart,
        currencyCode: currencyCode,
        rateToUsdAtSale: rateToUsdAtSale,
        employeeId: employeeId, 
      );
      emit(
        state.copyWith(
          status: SalesStatus.success,
          lastSaleId: saleId,
          cart: [],
          totalPrice: 0.0,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: SalesStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  void _recalculateAndEmit(List<SaleItem> cart) {
    double tempTotalPrice = 0.0;
    double tempTotalProfit = 0.0;

    for (var item in cart) {
      tempTotalPrice += item.subtotal;
      tempTotalProfit +=
          (item.sellingPrice - item.product.costPrice) * item.quantity;
    }

    emit(
      state.copyWith(
        cart: cart,
        totalPrice: tempTotalPrice,
        totalProfit: tempTotalProfit,
        status: SalesStatus.initial,
      ),
    );
  }
}