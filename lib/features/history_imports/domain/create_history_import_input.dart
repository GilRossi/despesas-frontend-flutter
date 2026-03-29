import 'package:despesas_frontend/features/history_imports/domain/history_import_entry_input.dart';
import 'package:despesas_frontend/features/history_imports/domain/history_import_payment_method.dart';

class CreateHistoryImportInput {
  const CreateHistoryImportInput({
    required this.entries,
    required this.paymentMethod,
  });

  final List<HistoryImportEntryInput> entries;
  final HistoryImportPaymentMethod paymentMethod;

  Map<String, Object?> toJson() {
    return {
      'entries': entries.map((entry) => entry.toJson()).toList(growable: false),
      'paymentMethod': paymentMethod.apiValue,
    };
  }
}
