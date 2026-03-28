import 'package:despesas_frontend/features/incomes/domain/create_income_input.dart';
import 'package:despesas_frontend/features/incomes/domain/income_record.dart';

abstract interface class IncomesRepository {
  Future<IncomeRecord> createIncome(CreateIncomeInput input);
}
