
import 'package:equatable/equatable.dart';
import 'package:hasbni/data/models/sale_model.dart';

enum SalesStatus { initial, loading, success, failure }

class SalesState extends Equatable {
  final List<SaleItem> cart;
  final double totalPrice;
  final double totalProfit; 
  final SalesStatus status;
  final String? errorMessage;
  final int? lastSaleId;

  const SalesState({
    this.cart = const [],
    this.totalPrice = 0.0,
    this.totalProfit = 0.0, 
    this.status = SalesStatus.initial,
    this.errorMessage,
    this.lastSaleId,
  });

  SalesState copyWith({
    List<SaleItem>? cart,
    double? totalPrice,
    double? totalProfit, 
    SalesStatus? status,
    String? errorMessage,
    int? lastSaleId,
  }) {
    return SalesState(
      cart: cart ?? this.cart,
      totalPrice: totalPrice ?? this.totalPrice,
      totalProfit: totalProfit ?? this.totalProfit, 
      status: status ?? this.status,
      errorMessage: errorMessage,
      lastSaleId: lastSaleId,
    );
  }

  @override
  List<Object?> get props => [
    cart,
    totalPrice,
    totalProfit,
    status,
    errorMessage,
    lastSaleId,
  ];
}
