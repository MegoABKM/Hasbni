
import 'package:hasbni/data/models/sale_detail_model.dart';
import 'package:hasbni/data/models/sale_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SalesRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<int> createSale({
    required List<SaleItem> items,
    required String currencyCode,
    required double rateToUsdAtSale,
    int? employeeId,
  }) async {
    try {
      final itemsJson = items.map((item) => item.toRpcJson()).toList();
      final params = {
        'p_sale_items_data': itemsJson,
        'p_currency_code': currencyCode,
        'p_rate_to_usd_at_sale': rateToUsdAtSale,
        'p_employee_id': employeeId,
      };
      
      params.removeWhere((key, value) => value == null);

      final saleId = await _client.rpc(
        'create_sale_and_update_inventory',
        params: params,
      );
      return (saleId as num).toInt();
    } catch (e) {
      print('Error creating sale: $e');
      rethrow;
    }
  }

  Future<List<Sale>> getSalesHistory({
    required int page,
    required int limit,
  }) async {
    final data = await _client
        .from('sales')
        .select('id, total_price, currency_code, created_at')
        .order('created_at', ascending: false)
        .range(page * limit, (page * limit) + limit - 1);
    return data.map((item) => Sale.fromJson(item)).toList();
  }

  Future<SaleDetail> getSaleDetails(int saleId) async {
    try {
      final data = await _client.rpc(
        'get_sale_details',
        params: {'p_sale_id': saleId},
      );
      return SaleDetail.fromJson(data);
    } catch (e) {
      print('Error getting sale details: $e');
      rethrow;
    }
  }

  Future<void> processReturn(int saleItemId, int returnQuantity) async {
    try {
      await _client.rpc(
        'process_return',
        params: {
          'p_sale_item_id': saleItemId,
          'p_return_quantity': returnQuantity,
        },
      );
    } catch (e) {
      print('Error processing return: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> processExchange({
    required int saleItemIdToReturn,
    required int returnQuantity,
    required List<SaleItem> newItems,
    required String currencyCode,
    required double rateToUsdAtSale,
    int? employeeId, 
  }) async {
    try {
      final newItemsJson = newItems.map((item) => item.toRpcJson()).toList();
      
      final params = {
        'p_sale_item_id_to_return': saleItemIdToReturn,
        'p_return_quantity': returnQuantity,
        'p_new_sale_items_data': newItemsJson,
        'p_currency_code': currencyCode,
        'p_rate_to_usd_at_sale': rateToUsdAtSale,
        'p_employee_id': employeeId, 
      };
      
      params.removeWhere((key, value) => value == null);

      final result = await _client.rpc(
        'process_exchange',
        params: params, 
      );
      return result as Map<String, dynamic>;
    } catch (e) {
      print('Error processing exchange: $e');
      rethrow;
    }
  }
}
