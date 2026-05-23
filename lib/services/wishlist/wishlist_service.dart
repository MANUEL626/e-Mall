import '../../core/commerce/customer_shopping_service.dart';

export '../../core/commerce/customer_shopping_service.dart' show CustomerShoppingService;

class WishlistService {
  WishlistService._();

  static CustomerShoppingService get instance => CustomerShoppingService.instance;
}
