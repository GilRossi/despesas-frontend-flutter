class ForgotPasswordResult {
  ForgotPasswordResult({
    required this.maskedEmail,
    this.resetToken,
  });

  final String maskedEmail;
  final String? resetToken;
}
