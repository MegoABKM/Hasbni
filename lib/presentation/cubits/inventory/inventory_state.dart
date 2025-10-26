// lib/presentation/cubits/inventory/inventory_state.dart

import 'package:equatable/equatable.dart';
import 'package:hasbni/data/models/product_model.dart';

enum InventoryStatus { initial, loading, success, failure, loadingMore }

// Enum للتحكم في خيارات الفرز
enum SortBy { name, quantity, sellingPrice, createdAt }

class InventoryState extends Equatable {
  final InventoryStatus status;
  final List<Product> products; // الآن لدينا قائمة واحدة فقط
  final String? errorMessage;

  // متغيرات الحالة الجديدة للترقيم والفرز
  final bool hasMore;
  final int page;
  final String? searchQuery;
  final SortBy sortBy;
  final bool ascending;

  const InventoryState({
    this.status = InventoryStatus.initial,
    this.products = const [],
    this.errorMessage,
    this.hasMore = true,
    this.page = 0,
    this.searchQuery,
    this.sortBy = SortBy.name, // الفرز الافتراضي بالاسم
    this.ascending = true,
  });

  InventoryState copyWith({
    InventoryStatus? status,
    List<Product>? products,
    String? errorMessage,
    bool? hasMore,
    int? page,
    // نسمح بإلغاء البحث عن طريق تمرير null
    String? Function()? searchQuery,
    SortBy? sortBy,
    bool? ascending,
  }) {
    return InventoryState(
      status: status ?? this.status,
      products: products ?? this.products,
      errorMessage: errorMessage,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      searchQuery: searchQuery != null ? searchQuery() : this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
    );
  }

  @override
  List<Object?> get props => [
    status,
    products,
    errorMessage,
    hasMore,
    page,
    searchQuery,
    sortBy,
    ascending,
  ];
}
