class ResetPasswordResult {
  const ResetPasswordResult({
    required this.revokedRefreshTokens,
    required this.success,
  });

  final int revokedRefreshTokens;
  final bool success;
}
