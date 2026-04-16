import 'package:despesas_frontend/features/driver_module/domain/driver_module_bootstrap.dart';

abstract interface class DriverModuleRepository {
  Future<DriverModuleBootstrap> fetchBootstrap();
}
