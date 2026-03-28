enum SpaceReferenceTypeGroup {
  residencial(apiValue: 'RESIDENCIAL', label: 'Residencial'),
  comercialTrabalho(
    apiValue: 'COMERCIAL_TRABALHO',
    label: 'Comercial e trabalho',
  ),
  veiculos(apiValue: 'VEICULOS', label: 'Veiculos'),
  embarcacao(apiValue: 'EMBARCACAO', label: 'Embarcacao'),
  aviacao(apiValue: 'AVIACAO', label: 'Aviacao');

  const SpaceReferenceTypeGroup({required this.apiValue, required this.label});

  final String apiValue;
  final String label;

  static SpaceReferenceTypeGroup fromApiValue(String value) {
    return values.firstWhere(
      (group) => group.apiValue == value,
      orElse: () => throw ArgumentError.value(
        value,
        'value',
        'Grupo de referencia desconhecido.',
      ),
    );
  }
}
