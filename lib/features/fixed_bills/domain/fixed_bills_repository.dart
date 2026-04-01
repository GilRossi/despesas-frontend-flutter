import 'package:despesas_frontend/features/fixed_bills/domain/create_fixed_bill_input.dart';
import 'package:despesas_frontend/features/fixed_bills/domain/fixed_bill_record.dart';

abstract interface class FixedBillsRepository {
  Future<List<FixedBillRecord>> listFixedBills();

  Future<FixedBillRecord> createFixedBill(CreateFixedBillInput input);
}
