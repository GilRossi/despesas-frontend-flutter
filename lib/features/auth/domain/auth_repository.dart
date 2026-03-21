import 'package:despesas_frontend/features/auth/domain/mobile_session.dart';

abstract interface class AuthRepository {
  Future<MobileSession> login({
    required String email,
    required String password,
  });

  Future<MobileSession> refresh({required String refreshToken});
}
