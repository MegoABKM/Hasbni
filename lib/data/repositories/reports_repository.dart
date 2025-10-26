// lib/data/repositories/reports_repository.dart
import 'package:hasbni/data/models/financial_summary_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportsRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<FinancialSummary> getFinancialSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final result = await _client.rpc(
        'get_financial_summary',
        params: {
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
        },
      );
      return FinancialSummary.fromJson(result);
    } catch (e) {
      print('Error fetching financial summary: $e');
      rethrow;
    }
  }
}
