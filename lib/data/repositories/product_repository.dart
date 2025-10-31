

import 'package:hasbni/data/models/product_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductRepository {
  final SupabaseClient _client = Supabase.instance.client;
  final String _tableName = 'products';

  
  Future<List<Product>> getProducts({
    required int page,
    required int limit,
    required String sortBy,
    required bool ascending,
    String? searchQuery,
  }) async {
    try {
      final from = page * limit;
      final to = from + limit - 1;

      var query = _client.from(_tableName).select();

      
      if (searchQuery != null && searchQuery.isNotEmpty) {
        
        final queryLower = '%${searchQuery.toLowerCase()}%';
        query = query.or('name.ilike.$queryLower,barcode.ilike.$queryLower');
      }

      
      final data = await query
          .order(sortBy, ascending: ascending)
          .range(from, to);

      final products = data.map((item) => Product.fromJson(item)).toList();
      return products;
    } catch (e) {
      print('Error fetching products: $e');
      rethrow;
    }
  }

  
  Future<void> addProduct(Map<String, dynamic> productData) async {
    try {
      await _client.from(_tableName).insert(productData);
    } catch (e) {
      print('Error adding product: $e');
      rethrow;
    }
  }

  
  Future<void> updateProduct(
    int productId,
    Map<String, dynamic> productData,
  ) async {
    try {
      await _client.from(_tableName).update(productData).eq('id', productId);
    } catch (e) {
      print('Error updating product: $e');
      rethrow;
    }
  }

  
  Future<void> deleteProduct(int productId) async {
    try {
      await _client.from(_tableName).delete().eq('id', productId);
    } catch (e) {
      print('Error deleting product: $e');
      rethrow;
    }
  }
}
