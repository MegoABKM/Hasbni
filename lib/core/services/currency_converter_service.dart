// lib/core/services/currency_converter_service.dart
import 'package:hasbni/data/models/profile_model.dart';

class CurrencyConverterService {
  final Profile? profile;

  CurrencyConverterService(this.profile);

  /// Converts a price from the base accounting currency (USD) to a target currency.
  double convert(double originalPriceInUsd, String targetCurrency) {
    if (targetCurrency == 'USD') {
      return originalPriceInUsd;
    }
    if (profile == null || profile!.exchangeRates.isEmpty) {
      return originalPriceInUsd;
    }
    try {
      final targetRate = profile!.exchangeRates
          .firstWhere((r) => r.currencyCode == targetCurrency)
          .rateToUsd;

      if (targetRate <= 0) return originalPriceInUsd;

      return originalPriceInUsd * targetRate;
    } catch (e) {
      return originalPriceInUsd; // Fallback to USD if rate not found
    }
  }
}
