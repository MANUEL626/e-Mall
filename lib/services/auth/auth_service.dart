import '../../core/auth/customer_auth_service.dart';

export '../../core/auth/auth_entry_prefs.dart';
export '../../core/auth/auth_gate_service.dart';
export '../../core/auth/bootstrap_customer_result.dart';
export '../../core/auth/customer_auth_service.dart';
export '../../core/auth/sign_out_ui.dart';

class AuthService {
  AuthService._();

  static CustomerAuthService get instance => CustomerAuthService.instance;
}
