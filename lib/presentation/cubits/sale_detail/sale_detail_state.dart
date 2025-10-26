// lib/presentation/cubits/sale_detail/sale_detail_state.dart
import 'package:equatable/equatable.dart';
import 'package:hasbni/data/models/sale_detail_model.dart';

enum SaleDetailStatus {
  initial,
  loading,
  success,
  failure,
  processingReturn,
  returnSuccess,
  returnFailure,
}

class SaleDetailState extends Equatable {
  final SaleDetailStatus status;
  final SaleDetail? saleDetail;
  final String? errorMessage;
  final String? successMessage;

  const SaleDetailState({
    this.status = SaleDetailStatus.initial,
    this.saleDetail,
    this.errorMessage,
    this.successMessage,
  });

  SaleDetailState copyWith({
    SaleDetailStatus? status,
    SaleDetail? saleDetail,
    String? errorMessage,
    String? successMessage,
  }) {
    return SaleDetailState(
      status: status ?? this.status,
      saleDetail: saleDetail ?? this.saleDetail,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [status, saleDetail, errorMessage, successMessage];
}
