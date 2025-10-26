// lib/core/services/search_service.dart
import 'package:hasbni/data/models/product_model.dart';
import 'package:hasbni/data/repositories/product_repository.dart';

class SearchService {
  final ProductRepository _productRepository = ProductRepository();

  /// يبحث عن المنتجات ويعيد قائمة بالنتائج
  Future<List<Product>> searchProducts(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }
    try {
      return await _productRepository.getProducts(
        page: 0,
        limit: 20, // يمكن زيادة الحد إذا أردت عرض المزيد من النتائج
        sortBy: 'name',
        ascending: true,
        searchQuery: query,
      );
    } catch (e) {
      print("Error in SearchService: $e");
      return []; // أعد قائمة فارغة في حالة حدوث خطأ
    }
  }
}
