
import 'package:hasbni/data/models/profile_model.dart';

class CurrencyConverterService {
  final Profile? profile;

  CurrencyConverterService(this.profile);

  
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
      return originalPriceInUsd; 
    }
  }
}
