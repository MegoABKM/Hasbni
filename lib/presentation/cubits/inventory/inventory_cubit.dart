// lib/presentation/cubits/inventory/inventory_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hasbni/data/repositories/product_repository.dart';
import 'package:hasbni/presentation/cubits/inventory/inventory_state.dart';

class InventoryCubit extends Cubit<InventoryState> {
  final ProductRepository _productRepository;
  static const int _limit = 20; // عدد المنتجات لكل صفحة

  InventoryCubit()
    : _productRepository = ProductRepository(),
      super(const InventoryState());

  /// الدالة الرئيسية لجلب البيانات، مع دعم التحديث
  Future<void> loadProducts({bool isRefresh = false}) async {
    if (isRefresh) {
      emit(state.copyWith(page: 0, hasMore: true, products: []));
    }

    // منع الطلبات المتكررة إذا كنا في حالة تحميل أو لا يوجد المزيد من البيانات
    if (state.status == InventoryStatus.loading ||
        state.status == InventoryStatus.loadingMore ||
        !state.hasMore)
      return;

    final isLoadingFirstTime = state.page == 0;
    emit(
      state.copyWith(
        status: isLoadingFirstTime
            ? InventoryStatus.loading
            : InventoryStatus.loadingMore,
      ),
    );

    try {
      final newProducts = await _productRepository.getProducts(
        page: state.page,
        limit: _limit,
        sortBy: _mapSortByToString(state.sortBy),
        ascending: state.ascending,
        searchQuery: state.searchQuery,
      );

      emit(
        state.copyWith(
          status: InventoryStatus.success,
          products: List.of(state.products)..addAll(newProducts),
          page: state.page + 1,
          hasMore: newProducts.length == _limit,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: InventoryStatus.failure,
          errorMessage: 'فشل في جلب البيانات.',
        ),
      );
    }
  }

  /// دالة لتغيير الفرز وإعادة تحميل البيانات
  Future<void> changeSort({required SortBy sortBy}) async {
    final newAscending = (sortBy == state.sortBy) ? !state.ascending : true;
    emit(state.copyWith(sortBy: sortBy, ascending: newAscending));
    await loadProducts(isRefresh: true);
  }

  /// دالة للبحث وإعادة تحميل البيانات
  Future<void> searchProducts(String query) async {
    emit(state.copyWith(searchQuery: () => query));
    await loadProducts(isRefresh: true);
  }

  /// دالة لإعادة تحميل كل شيء من البداية
  Future<void> refresh() async {
    await loadProducts(isRefresh: true);
  }

  /// إضافة منتج ثم تحديث القائمة
  Future<void> addProduct(Map<String, dynamic> productData) async {
    try {
      await _productRepository.addProduct(productData);
      await refresh();
    } catch (e) {
      // يمكنك إصدار حالة خطأ خاصة هنا إذا أردت
      print('Error adding and refreshing: $e');
    }
  }

  /// تعديل منتج ثم تحديث القائمة
  Future<void> updateProduct(
    int productId,
    Map<String, dynamic> productData,
  ) async {
    try {
      await _productRepository.updateProduct(productId, productData);
      await refresh();
    } catch (e) {
      print('Error updating and refreshing: $e');
    }
  }

  /// حذف منتج ثم تحديث القائمة
  Future<void> deleteProduct(int productId) async {
    try {
      await _productRepository.deleteProduct(productId);
      await refresh();
    } catch (e) {
      print('Error deleting and refreshing: $e');
    }
  }

  // دالة مساعدة لتحويل enum إلى نص يفهمه Supabase
  String _mapSortByToString(SortBy sortBy) {
    switch (sortBy) {
      case SortBy.quantity:
        return 'quantity';
      case SortBy.sellingPrice:
        return 'selling_price';
      case SortBy.createdAt:
        return 'created_at';
      case SortBy.name:
        return 'name';
    }
  }
}
