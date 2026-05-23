import '../../core/commerce/customer_sale_service.dart';

export '../../core/commerce/customer_sale_models.dart';
export '../../core/commerce/customer_sale_service.dart';
export '../../core/commerce/emall_deep_link.dart';

class OrdersService {
  OrdersService._();

  static CustomerSaleService get instance => CustomerSaleService.instance;
}
