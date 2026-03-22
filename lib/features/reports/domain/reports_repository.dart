import 'package:despesas_frontend/features/reports/domain/reports_snapshot.dart';

abstract interface class ReportsRepository {
  Future<ReportsSnapshot> loadMonthlyReport({
    required DateTime referenceMonth,
    required bool comparePrevious,
  });
}
