class ExpenseReference {
  const ExpenseReference({required this.id, required this.name});

  final int id;
  final String name;

  factory ExpenseReference.fromJson(Map<String, dynamic> json) {
    return ExpenseReference(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}
