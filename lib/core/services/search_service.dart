
import 'package:hasbni/data/models/product_model.dart';
import 'package:hasbni/data/repositories/product_repository.dart';

class SearchService {
  final ProductRepository _productRepository = ProductRepository();

  
  Future<List<Product>> searchProducts(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }
    try {
      return await _productRepository.getProducts(
        page: 0,
        limit: 20, 
        sortBy: 'name',
        ascending: true,
        searchQuery: query,
      );
    } catch (e) {
      print("Error in SearchService: $e");
      return []; 
    }
  }
}
