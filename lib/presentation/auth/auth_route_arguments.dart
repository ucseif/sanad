import '../../domain/models/user_role.dart';

/// Presentation-only state carried between authentication screens.
///
/// It intentionally contains no credential or backend state. The email is
/// retained only long enough to render the verification preview.
class AuthRouteArguments {
  const AuthRouteArguments({required this.role, this.email});

  final UserRole role;
  final String? email;

  AuthRouteArguments copyWith({UserRole? role, String? email}) {
    return AuthRouteArguments(role: role ?? this.role, email: email ?? this.email);
  }
}
