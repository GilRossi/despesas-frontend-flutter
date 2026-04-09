enum FinancialAssistantStarterIntent {
  fixedBills(
    apiValue: 'FIXED_BILLS',
    label: 'Cadastrar minhas contas fixas',
    description: 'Comece pelos compromissos que se repetem todo mês.',
  ),
  importHistory(
    apiValue: 'IMPORT_HISTORY',
    label: 'Trazer meu histórico',
    description: 'Organize o que já aconteceu antes de planejar o resto.',
  ),
  registerIncome(
    apiValue: 'REGISTER_INCOME',
    label: 'Cadastrar meus ganhos',
    description: 'Mostre quanto entra para completar seu espaço.',
  ),
  configureSpace(
    apiValue: 'CONFIGURE_SPACE',
    label: 'Configurar meu espaço',
    description: 'Ajuste pessoas e regras do seu espaço.',
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
