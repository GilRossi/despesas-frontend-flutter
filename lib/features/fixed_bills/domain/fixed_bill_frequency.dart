enum FixedBillFrequency {
  monthly('MONTHLY', 'Mensal');

  const FixedBillFrequency(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static FixedBillFrequency fromApiValue(String value) {
    return FixedBillFrequency.values.firstWhere(
      (item) => item.apiValue == value,
      orElse: () => FixedBillFrequency.monthly,
    );
  }
}
