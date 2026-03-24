import 'package:despesas_frontend/features/auth/domain/mobile_session.dart';
import 'package:despesas_frontend/features/auth/domain/change_password_result.dart';

abstract interface class AuthRepository {
  Future<MobileSession> login({
    required String email,
    required String password,
  });

  Future<MobileSession> refresh({required String refreshToken});

  Future<ChangePasswordResult> changeOwnPassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  });
}
