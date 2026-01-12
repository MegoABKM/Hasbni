import 'package:hasbni/core/services/api_services.dart';
import 'package:hasbni/data/models/exchange_rate_model.dart';

class ExchangeRateRepository {
  final ApiService _api = ApiService();

  Future<void> upsertExchangeRates(List<ExchangeRate> rates) async {
    // Exchange rates are usually updated via the Profile endpoint
    // This is just a placeholder to satisfy potential cubit dependencies
  }
}