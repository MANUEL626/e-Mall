import '../../core/commerce/customer_shopping_service.dart';

export '../../core/commerce/customer_shopping_service.dart' show CustomerShoppingService;
export '../../core/commerce/shopping_cart_models.dart';

class CartService {
  CartService._();

  static CustomerShoppingService get instance => CustomerShoppingService.instance;
}
