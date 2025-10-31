
import 'package:equatable/equatable.dart';
import 'package:hasbni/data/models/sale_model.dart'; 

enum SalesHistoryStatus { initial, loading, success, failure, loadingMore }

class SalesHistoryState extends Equatable {
  final SalesHistoryStatus status;
  final List<Sale> sales; 
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
    List<Sale>? sales, 
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
