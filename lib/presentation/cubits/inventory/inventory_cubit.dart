import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hasbni/data/repositories/product_repository.dart';
import 'package:hasbni/presentation/cubits/inventory/inventory_state.dart';

class InventoryCubit extends Cubit<InventoryState> {
  final ProductRepository _productRepository;
  static const int _limit = 20;

  InventoryCubit()
      : _productRepository = ProductRepository(),
        super(const InventoryState());

  Future<void> loadProducts({bool isRefresh = false}) async {
    if (isRefresh) {
      // Reset to initial state for refresh
      emit(state.copyWith(
        page: 0,
        hasMore: true,
        products: [],
        status: InventoryStatus.loading, // Show spinner
      ));
    } else {
      if (state.status == InventoryStatus.loading || !state.hasMore) return;
      emit(state.copyWith(status: InventoryStatus.loadingMore));
    }

    try {
      final newProducts = await _productRepository.getProducts(
        page: state.page,
        limit: _limit,
        sortBy: _mapSortByToString(state.sortBy),
        ascending: state.ascending,
        searchQuery: state.searchQuery,
      );

      emit(state.copyWith(
        status: InventoryStatus.success,
        products: [...state.products, ...newProducts], // Append lists
        page: state.page + 1,
        hasMore: newProducts.length == _limit,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: InventoryStatus.failure,
        errorMessage: 'فشل في جلب البيانات: $e',
      ));
    }
  }

  // --- CRUD Operations ---

  Future<void> addProduct(Map<String, dynamic> productData) async {
    try {
      emit(state.copyWith(status: InventoryStatus.loading)); // Show loading
      await _productRepository.addProduct(productData);
      await refresh(); // Reload list from DB
    } catch (e) {
      emit(state.copyWith(
          status: InventoryStatus.failure, errorMessage: "Error: $e"));
    }
  }

  Future<void> updateProduct(
      int productId, Map<String, dynamic> productData) async {
    try {
      emit(state.copyWith(status: InventoryStatus.loading));
      await _productRepository.updateProduct(productId, productData);
      await refresh();
    } catch (e) {
      print('Error updating: $e');
    }
  }

  Future<void> deleteProduct(int productId) async {
    try {
      // Optimistic update: Remove from UI immediately
      final updatedList =
          state.products.where((p) => p.localId != productId).toList();
      emit(state.copyWith(products: updatedList));

      await _productRepository.deleteProduct(productId);
      await refresh(); // Ensure sync with DB
    } catch (e) {
      print('Error deleting: $e');
    }
  }

 Future<void> refresh() async {
    // 1. Emit loading state to force UI to show spinner
    emit(state.copyWith(
      status: InventoryStatus.loading, 
      products: [], // Clear list temporarily to force rebuild
      page: 0,
      hasMore: true
    ));
    
    // 2. Clear search query if it was set (optional, but good for UX on add)
    // emit(state.copyWith(searchQuery: () => null)); 

    // 3. Load data fresh
    await loadProducts(isRefresh: true);
  }
  // ... Sort Helpers (Search, changeSort) same as before ...
  Future<void> searchProducts(String query) async {
    emit(state.copyWith(searchQuery: () => query));
    await loadProducts(isRefresh: true);
  }

  Future<void> changeSort({required SortBy sortBy}) async {
    final newAscending = (sortBy == state.sortBy) ? !state.ascending : true;
    emit(state.copyWith(sortBy: sortBy, ascending: newAscending));
    await loadProducts(isRefresh: true);
  }

  String _mapSortByToString(SortBy sortBy) {
    switch (sortBy) {
      case SortBy.quantity: return 'quantity';
      case SortBy.sellingPrice: return 'selling_price';
      case SortBy.createdAt: return 'created_at';
      case SortBy.name: return 'name';
    }
  }
}