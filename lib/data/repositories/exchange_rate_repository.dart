
import 'package:hasbni/data/models/exchange_rate_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExchangeRateRepository {
  final SupabaseClient _client = Supabase.instance.client;
  final String _tableName = 'exchange_rates';

  
  Future<List<ExchangeRate>> getExchangeRates() async {
    final data = await _client.from(_tableName).select();
    return data.map((item) => ExchangeRate.fromJson(item)).toList();
  }

  
  Future<void> upsertExchangeRates(List<ExchangeRate> rates) async {
    final dataToUpsert = rates.map((rate) => rate.toJson()).toList();
    await _client
        .from(_tableName)
        .upsert(dataToUpsert, onConflict: 'user_id, currency_code');
  }

  
  Future<void> deleteExchangeRate(int id) async {
    await _client.from(_tableName).delete().eq('id', id);
  }
}
