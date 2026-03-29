import 'package:despesas_frontend/features/history_imports/domain/create_history_import_input.dart';
import 'package:despesas_frontend/features/history_imports/domain/history_import_result.dart';

abstract interface class HistoryImportsRepository {
  Future<HistoryImportResult> importHistory(CreateHistoryImportInput input);
}
