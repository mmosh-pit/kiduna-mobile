class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.uuid,
    this.picture,
    this.banner,
    this.displayName,
    this.lastName,
    this.username,
    this.bio,
    this.wallet,
    this.kinshipCode,
    this.role,
    this.onboardingStep,
    this.onboardingStatus,
  });

  final String id;
  final String email;
  final String name;
  final String? uuid;
  final String? picture;
  final String? banner;
  final String? displayName;
  final String? lastName;
  final String? username;
  final String? bio;
  final String? wallet;
  final String? kinshipCode;
  final String? role;
  final int? onboardingStep;
  final String? onboardingStatus;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: (json['name'] as String?) ?? '',
      uuid: json['uuid'] as String?,
      picture: json['picture'] as String?,
      banner: json['banner'] as String?,
      displayName: json['display_name'] as String?,
      lastName: json['last_name'] as String?,
      username: json['username'] as String?,
      bio: json['bio'] as String?,
      wallet: json['wallet'] as String?,
      kinshipCode: json['kinship_code'] as String?,
      role: json['role'] as String?,
      onboardingStep: json['onboarding_step'] as int?,
      onboardingStatus: json['onboarding_status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'uuid': uuid,
      'picture': picture,
      'banner': banner,
      'display_name': displayName,
      'last_name': lastName,
      'username': username,
      'bio': bio,
      'wallet': wallet,
      'kinship_code': kinshipCode,
      'role': role,
      'onboarding_step': onboardingStep,
      'onboarding_status': onboardingStatus,
    };
  }
}

class AuthResponse {
  const AuthResponse({required this.token, required this.user});

  final String token;
  final UserModel user;

  /// Parses login response: `{ data: { token, user } }`
  factory AuthResponse.fromLoginJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return AuthResponse(
      token: data['token'] as String,
      user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  /// Parses visitors signup response: `{ status, token, user }`
  factory AuthResponse.fromVisitorJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
