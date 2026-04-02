enum SpaceReferenceTypeGroup {
  residencial(apiValue: 'RESIDENCIAL', label: 'Residencial'),
  comercialTrabalho(
    apiValue: 'COMERCIAL_TRABALHO',
    label: 'Comercial e trabalho',
  ),
  veiculos(apiValue: 'VEICULOS', label: 'Veículos'),
  embarcacao(apiValue: 'EMBARCACAO', label: 'Embarcação'),
  aviacao(apiValue: 'AVIACAO', label: 'Aviação');

  const SpaceReferenceTypeGroup({required this.apiValue, required this.label});

  final String apiValue;
  final String label;

  static SpaceReferenceTypeGroup fromApiValue(String value) {
    return values.firstWhere(
      (group) => group.apiValue == value,
      orElse: () => throw ArgumentError.value(
        value,
        'value',
        'Grupo de referência desconhecido.',
      ),
    );
  }
}
