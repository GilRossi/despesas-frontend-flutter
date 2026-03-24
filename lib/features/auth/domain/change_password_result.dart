class ChangePasswordResult {
  const ChangePasswordResult({
    required this.revokedRefreshTokens,
    required this.reauthenticationRequired,
  });

  final int revokedRefreshTokens;
  final bool reauthenticationRequired;

  factory ChangePasswordResult.fromJson(Map<String, dynamic> json) {
    return ChangePasswordResult(
      revokedRefreshTokens: json['revokedRefreshTokens'] as int? ?? 0,
      reauthenticationRequired:
          json['reauthenticationRequired'] as bool? ?? true,
    );
  }
}
