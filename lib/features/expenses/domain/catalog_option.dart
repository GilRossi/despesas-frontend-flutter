import 'package:despesas_frontend/features/expenses/domain/expense_reference.dart';

class CatalogOption {
  const CatalogOption({
    required this.id,
    required this.name,
    required this.subcategories,
  });

  final int id;
  final String name;
  final List<ExpenseReference> subcategories;

  factory CatalogOption.fromJson(Map<String, dynamic> json) {
    return CatalogOption(
      id: _toInt(json['id']),
      name: json['name'] as String,
      subcategories: (json['subcategories'] as List<dynamic>? ?? const [])
          .map(
            (item) => ExpenseReference.fromJson(item as Map<String, dynamic>),
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
