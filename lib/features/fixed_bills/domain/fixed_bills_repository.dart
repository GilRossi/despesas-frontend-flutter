import 'package:despesas_frontend/features/fixed_bills/domain/create_fixed_bill_input.dart';
import 'package:despesas_frontend/features/fixed_bills/domain/fixed_bill_record.dart';
import 'package:despesas_frontend/features/expenses/domain/expense_summary.dart';

abstract interface class FixedBillsRepository {
  Future<List<FixedBillRecord>> listFixedBills();

  Future<FixedBillRecord> getFixedBill(int fixedBillId);

  Future<FixedBillRecord> createFixedBill(CreateFixedBillInput input);

  Future<FixedBillRecord> updateFixedBill({
    required int fixedBillId,
    required CreateFixedBillInput input,
  });

  Future<void> deleteFixedBill(int fixedBillId);

  Future<ExpenseSummary> launchNextExpense(int fixedBillId);
}
