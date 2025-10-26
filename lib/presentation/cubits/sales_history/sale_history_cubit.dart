// lib/presentation/cubits/sales_history/sales_history_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hasbni/data/repositories/sales_repository.dart';
import 'package:hasbni/presentation/cubits/sales_history/sale_history_state.dart';

class SalesHistoryCubit extends Cubit<SalesHistoryState> {
  final SalesRepository _salesRepository;
  static const int _limit = 20;

  SalesHistoryCubit()
    : _salesRepository = SalesRepository(),
      super(const SalesHistoryState());

  Future<void> loadSales({bool isRefresh = false}) async {
    if (isRefresh) {
      emit(state.copyWith(page: 0, hasMore: true, sales: []));
    }
    if (state.status == SalesHistoryStatus.loading ||
        state.status == SalesHistoryStatus.loadingMore ||
        !state.hasMore)
      return;

    emit(
      state.copyWith(
        status: state.page == 0
            ? SalesHistoryStatus.loading
            : SalesHistoryStatus.loadingMore,
      ),
    );

    try {
      final newSales = await _salesRepository.getSalesHistory(
        page: state.page,
        limit: _limit,
      );
      emit(
        state.copyWith(
          status: SalesHistoryStatus.success,
          sales: List.of(state.sales)..addAll(newSales),
          page: state.page + 1,
          hasMore: newSales.length == _limit,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SalesHistoryStatus.failure,
          errorMessage: 'فشل تحميل السجل.',
        ),
      );
    }
  }
}
