import 'package:despesas_frontend/features/history_imports/domain/history_import_payment_method.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromApiValue resolves all supported payment methods', () {
    for (final method in HistoryImportPaymentMethod.values) {
      expect(
        HistoryImportPaymentMethod.fromApiValue(method.apiValue),
        method,
      );
      expect(method.label, isNotEmpty);
    }
  });

  test('fromApiValue throws for an unknown payment method', () {
    expect(
      () => HistoryImportPaymentMethod.fromApiValue('UNKNOWN'),
      throwsArgumentError,
    );
  });
}
