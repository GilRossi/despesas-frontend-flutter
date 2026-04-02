enum SpaceReferenceCreateResultType {
  created(apiValue: 'CREATED'),
  duplicateSuggestion(apiValue: 'DUPLICATE_SUGGESTION');

  const SpaceReferenceCreateResultType({required this.apiValue});

  final String apiValue;

  static SpaceReferenceCreateResultType fromApiValue(String value) {
    return values.firstWhere(
      (result) => result.apiValue == value,
      orElse: () => throw ArgumentError.value(
        value,
        'value',
        'Resultado de criação desconhecido.',
      ),
    );
  }
}
