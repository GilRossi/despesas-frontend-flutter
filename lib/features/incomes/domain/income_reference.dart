class IncomeReference {
  const IncomeReference({required this.id, required this.name});

  final int id;
  final String name;

  factory IncomeReference.fromJson(Map<String, dynamic> json) {
    return IncomeReference(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
    );
  }
}
