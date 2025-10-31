
import 'package:equatable/equatable.dart';

class ExchangeRate extends Equatable {
  final int? id;
  final String currencyCode;
  final double rateToUsd;

  const ExchangeRate({
    this.id,
    required this.currencyCode,
    required this.rateToUsd,
  });

  factory ExchangeRate.fromJson(Map<String, dynamic> json) {
    return ExchangeRate(
      id: json['id'],
      currencyCode: json['currency_code'],
      rateToUsd: (json['rate_to_usd'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    
    
    return {
      if (id != null) 'id': id,
      'currency_code': currencyCode,
      'rate_to_usd': rateToUsd,
    };
    
  }

  @override
  List<Object?> get props => [id, currencyCode, rateToUsd];
}
