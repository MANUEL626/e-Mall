import '../../core/catalog/customer_catalog_service.dart';

export '../../core/catalog/catalog_models.dart';
export '../../core/catalog/customer_catalog_service.dart';
export '../../core/catalog/product_image_url.dart';

class CatalogService {
  CatalogService._();

  static CustomerCatalogService get instance => CustomerCatalogService.instance;
}
