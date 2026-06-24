/// The signed-in user's basic profile (from POST /auth/login or /auth/google).
class AuthUser {
  final String userId;
  final String role;
  final String fullName;
  final String status;
  /// null  = Google Sign-In user who hasn't provided a phone number yet.
  /// ''    = legacy session loaded before phoneNumber was tracked (assume set).
  /// other = the actual phone number.
  final String? phoneNumber;
  /// false = Google-only account (no password set); hide "Change password".
  /// Defaults true for legacy stored sessions that pre-date this field.
  final bool hasPassword;

  AuthUser({
    required this.userId,
    required this.role,
    required this.fullName,
    required this.status,
    this.phoneNumber,
    this.hasPassword = true,
  });

  factory AuthUser.fromJson(Map<String, dynamic> j) => AuthUser(
        userId:      j['userId']   as String? ?? '',
        role:        j['role']     as String? ?? '',
        fullName:    j['fullName'] as String? ?? '',
        status:      j['status']   as String? ?? '',
        phoneNumber: j.containsKey('phoneNumber') ? j['phoneNumber'] as String? : '',
        hasPassword: j['hasPassword'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'userId':      userId,
        'role':        role,
        'fullName':    fullName,
        'status':      status,
        'phoneNumber': phoneNumber,
        'hasPassword': hasPassword,
      };
}

/// A successful login: the JWT plus the user it belongs to.
class UserSession {
  final String token;
  final AuthUser user;

  UserSession({required this.token, required this.user});

  factory UserSession.fromJson(Map<String, dynamic> j) => UserSession(
        token: j['token'] as String,
        user:  AuthUser.fromJson(j['user'] as Map<String, dynamic>),
      );
}
