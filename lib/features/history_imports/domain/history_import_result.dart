import 'package:despesas_frontend/features/history_imports/domain/history_import_entry_record.dart';

class HistoryImportResult {
  const HistoryImportResult({
    required this.importedCount,
    required this.entries,
  });

  final int importedCount;
  final List<HistoryImportEntryRecord> entries;

  factory HistoryImportResult.fromJson(Map<String, dynamic> json) {
    return HistoryImportResult(
      importedCount: _toInt(json['importedCount']),
      entries: (json['entries'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                HistoryImportEntryRecord.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }

  static int _toInt(Object? value) {
    return switch (value) {
      int number => number,
      double number => number.toInt(),
      String number => int.parse(number),
      _ => 0,
    };
  }
}
