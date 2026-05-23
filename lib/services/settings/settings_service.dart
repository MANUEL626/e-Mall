import '../../core/commerce/customer_sale_service.dart';

export '../../core/commerce/customer_sale_models.dart' show CustomerMeParams;
export '../../core/commerce/customer_sale_service.dart' show CustomerSaleService;
export '../../core/locale/app_locale_controller.dart';

class SettingsService {
  SettingsService._();

  static CustomerSaleService get instance => CustomerSaleService.instance;
}
