import '../../core/organizations/customer_organization_service.dart';

export '../../core/organizations/customer_organization_service.dart';
export '../../core/organizations/organization_models.dart';

class OrganizationsService {
  OrganizationsService._();

  static CustomerOrganizationService get instance =>
      CustomerOrganizationService.instance;
}
