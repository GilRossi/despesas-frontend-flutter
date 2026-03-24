class AdminPasswordResetInput {
  const AdminPasswordResetInput({
    required this.targetEmail,
    required this.newPassword,
    required this.newPasswordConfirmation,
  });

  final String targetEmail;
  final String newPassword;
  final String newPasswordConfirmation;
}
