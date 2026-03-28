import 'package:despesas_frontend/features/auth/domain/auth_user.dart';

class MobileSession {
  const MobileSession({
    required this.tokenType,
    required this.accessToken,
    required this.accessTokenExpiresAt,
    required this.refreshToken,
    required this.refreshTokenExpiresAt,
    required this.user,
  });

  final String tokenType;
  final String accessToken;
  final DateTime accessTokenExpiresAt;
  final String refreshToken;
  final DateTime refreshTokenExpiresAt;
  final AuthUser user;

  factory MobileSession.fromJson(Map<String, dynamic> json) {
    return MobileSession(
      tokenType: json['tokenType'] as String,
      accessToken: json['accessToken'] as String,
      accessTokenExpiresAt: DateTime.parse(
        json['accessTokenExpiresAt'] as String,
      ),
      refreshToken: json['refreshToken'] as String,
      refreshTokenExpiresAt: DateTime.parse(
        json['refreshTokenExpiresAt'] as String,
      ),
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  MobileSession copyWith({
    String? tokenType,
    String? accessToken,
    DateTime? accessTokenExpiresAt,
    String? refreshToken,
    DateTime? refreshTokenExpiresAt,
    AuthUser? user,
  }) {
    return MobileSession(
      tokenType: tokenType ?? this.tokenType,
      accessToken: accessToken ?? this.accessToken,
      accessTokenExpiresAt: accessTokenExpiresAt ?? this.accessTokenExpiresAt,
      refreshToken: refreshToken ?? this.refreshToken,
      refreshTokenExpiresAt:
          refreshTokenExpiresAt ?? this.refreshTokenExpiresAt,
      user: user ?? this.user,
    );
  }
}
