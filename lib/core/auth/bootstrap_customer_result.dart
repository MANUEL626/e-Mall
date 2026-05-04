/// Données renvoyées par `POST .../bootstrap` ou `PATCH .../profile` (même forme pratique).
class BootstrapCustomerResult {
  const BootstrapCustomerResult({
    required this.success,
    required this.message,
    required this.userId,
    required this.isNewCustomer,
    required this.profileComplete,
    this.username,
    this.prenom,
    this.nom,
    this.profilePicture,
    this.mail,
  });

  final bool success;
  final String? message;
  final String? userId;
  final bool isNewCustomer;
  final bool profileComplete;

  /// Champs optionnels renvoyés par l’API après bootstrap / profil.
  final String? username;
  final String? prenom;
  final String? nom;
  final String? profilePicture;
  final String? mail;

  factory BootstrapCustomerResult.fromJson(Map<String, dynamic> json) {
    return BootstrapCustomerResult(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      userId: json['user_id'] as String?,
      isNewCustomer: json['is_new_customer'] as bool? ?? false,
      profileComplete: json['profile_complete'] as bool? ?? false,
      username: json['username'] as String?,
      prenom: json['prenom'] as String?,
      nom: json['nom'] as String?,
      profilePicture: json['profilepicture'] as String? ?? json['profile_picture'] as String?,
      mail: json['mail'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'user_id': userId,
        'is_new_customer': isNewCustomer,
        'profile_complete': profileComplete,
        'username': username,
        'prenom': prenom,
        'nom': nom,
        'profilepicture': profilePicture,
        'mail': mail,
      };

  /// Nom affichable (prénom + nom, sinon pseudo, sinon libellé générique).
  String get displayName {
    final full = '${prenom ?? ''} ${nom ?? ''}'.trim();
    if (full.isNotEmpty) {
      return full;
    }
    final u = username?.trim();
    if (u != null && u.isNotEmpty) {
      return u;
    }
    return 'Profil';
  }
}

class CustomerBootstrapException implements Exception {
  CustomerBootstrapException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'CustomerBootstrapException: $message';
}
