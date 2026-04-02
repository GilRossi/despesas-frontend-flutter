enum FixedBillOperationalStatus {
  overdue('OVERDUE', 'Atrasada'),
  dueToday('DUE_TODAY', 'Vence hoje'),
  upcoming('UPCOMING', 'Em dia');

  const FixedBillOperationalStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static FixedBillOperationalStatus fromApiValue(String value) {
    return FixedBillOperationalStatus.values.firstWhere(
      (item) => item.apiValue == value,
      orElse: () => FixedBillOperationalStatus.upcoming,
    );
  }
}
