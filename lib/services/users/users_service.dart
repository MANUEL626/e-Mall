import '../../core/auth/customer_profile_store.dart';
import '../../core/commerce/customer_params_store.dart';

export '../../core/auth/customer_profile_store.dart';
export '../../core/commerce/customer_params_store.dart';
export '../../core/storage/profile_photo_storage.dart';

class UsersService {
  UsersService._();

  static CustomerProfileStore get profileStore => CustomerProfileStore.instance;
  static CustomerParamsStore get paramsStore => CustomerParamsStore.instance;
}
