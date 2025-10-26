// lib/presentation/cubits/sales_history/sales_history_state.dart
import 'package:equatable/equatable.dart';
import 'package:hasbni/data/models/sale_model.dart'; // <-- يجب أن يستورد Sale من هنا

enum SalesHistoryStatus { initial, loading, success, failure, loadingMore }

class SalesHistoryState extends Equatable {
  final SalesHistoryStatus status;
  final List<Sale> sales; // <-- النوع الصحيح هو List<Sale>
  final String? errorMessage;
  final bool hasMore;
  final int page;

  const SalesHistoryState({
    this.status = SalesHistoryStatus.initial,
    this.sales = const [],
    this.errorMessage,
    this.hasMore = true,
    this.page = 0,
  });

  SalesHistoryState copyWith({
    SalesHistoryStatus? status,
    List<Sale>? sales, // <-- النوع الصحيح هو List<Sale>
    String? errorMessage,
    bool? hasMore,
    int? page,
  }) {
    return SalesHistoryState(
      status: status ?? this.status,
      sales: sales ?? this.sales,
      errorMessage: errorMessage,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
    );
  }

  @override
  List<Object?> get props => [status, sales, errorMessage, hasMore, page];
}
