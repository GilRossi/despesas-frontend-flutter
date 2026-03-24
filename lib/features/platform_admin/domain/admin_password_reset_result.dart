class AdminPasswordResetResult {
  const AdminPasswordResetResult({
    required this.targetEmailMasked,
    required this.revokedRefreshTokens,
  });

  final String targetEmailMasked;
  final int revokedRefreshTokens;

  factory AdminPasswordResetResult.fromJson(Map<String, dynamic> json) {
    return AdminPasswordResetResult(
      targetEmailMasked: json['targetEmailMasked'] as String? ?? '-',
      revokedRefreshTokens: json['revokedRefreshTokens'] as int? ?? 0,
    );
  }
}
