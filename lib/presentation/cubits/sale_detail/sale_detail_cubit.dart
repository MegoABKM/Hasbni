// lib/presentation/cubits/sale_detail/sale_detail_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hasbni/data/models/sale_model.dart';
import 'package:hasbni/data/repositories/sales_repository.dart';
import 'package:hasbni/presentation/cubits/session/session_cubit.dart';
import 'sale_detail_state.dart';

class SaleDetailCubit extends Cubit<SaleDetailState> {
  final SalesRepository _salesRepository;
  final int saleId;
  final SessionCubit sessionCubit;
  SaleDetailCubit({required this.saleId, required this.sessionCubit})
    : _salesRepository = SalesRepository(),
      super(const SaleDetailState()) {
    loadSaleDetails();
  }

  Future<void> loadSaleDetails() async {
    emit(state.copyWith(status: SaleDetailStatus.loading));
    try {
      final saleDetail = await _salesRepository.getSaleDetails(saleId);
      emit(
        state.copyWith(
          status: SaleDetailStatus.success,
          saleDetail: saleDetail,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SaleDetailStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> returnItem(int saleItemId, int quantity) async {
    emit(state.copyWith(status: SaleDetailStatus.processingReturn));
    try {
      await _salesRepository.processReturn(saleItemId, quantity);
      emit(
        state.copyWith(
          status: SaleDetailStatus.returnSuccess,
          successMessage: 'تم الإرجاع بنجاح.',
        ),
      );
      await loadSaleDetails();
    } catch (e) {
      emit(
        state.copyWith(
          status: SaleDetailStatus.returnFailure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> exchangeItems({
    required int saleItemIdToReturn,
    required int returnQuantity,
    required List<SaleItem> newItems,
    required String currencyCode,
    required double rateToUsdAtSale,
  }) async {
    emit(state.copyWith(status: SaleDetailStatus.processingReturn));
    try {
      // << 4. GET the employeeId from the session state
      final employeeId = sessionCubit.state.currentEmployee?.id;

      final result = await _salesRepository.processExchange(
        saleItemIdToReturn: saleItemIdToReturn,
        returnQuantity: returnQuantity,
        newItems: newItems,
        currencyCode: currencyCode,
        rateToUsdAtSale: rateToUsdAtSale,
        employeeId: employeeId, // << 5. PASS the employeeId to the repository
      );
      final diff = (result['price_difference'] as num).toDouble();
      final currency = result['currency_code'] ?? currencyCode;

      emit(
        state.copyWith(
          status: SaleDetailStatus.returnSuccess,
          successMessage:
              'تم الاستبدال بنجاح. الفرق: ${diff.toStringAsFixed(2)} $currency',
        ),
      );
      await loadSaleDetails();
    } catch (e) {
      emit(
        state.copyWith(
          status: SaleDetailStatus.returnFailure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
