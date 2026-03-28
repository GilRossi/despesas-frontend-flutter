enum FinancialAssistantStarterIntent {
  fixedBills(
    apiValue: 'FIXED_BILLS',
    label: 'Cadastrar minhas contas fixas',
    description: 'Comece pelos compromissos que se repetem todo mes.',
  ),
  importHistory(
    apiValue: 'IMPORT_HISTORY',
    label: 'Trazer meu historico',
    description: 'Organize o que ja aconteceu antes de planejar o resto.',
  ),
  registerIncome(
    apiValue: 'REGISTER_INCOME',
    label: 'Cadastrar meus ganhos',
    description: 'Mostre quanto entra para o seu Espaco ficar completo.',
  ),
  configureSpace(
    apiValue: 'CONFIGURE_SPACE',
    label: 'Configurar meu Espaco',
    description: 'Ajuste pessoas e combinados do seu Espaco com calma.',
  );

  const FinancialAssistantStarterIntent({
    required this.apiValue,
    required this.label,
    required this.description,
  });

  final String apiValue;
  final String label;
  final String description;

  static FinancialAssistantStarterIntent fromApiValue(String value) {
    return values.firstWhere(
      (intent) => intent.apiValue == value,
      orElse: () => throw ArgumentError.value(
        value,
        'value',
        'Starter intent desconhecida.',
      ),
    );
  }
}
