class FixedBillReference {
  const FixedBillReference({required this.id, required this.name});

  final int id;
  final String name;

  factory FixedBillReference.fromJson(Map<String, dynamic> json) {
    return FixedBillReference(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
    );
  }
}
