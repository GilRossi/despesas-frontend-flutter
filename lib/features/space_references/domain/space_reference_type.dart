import 'package:despesas_frontend/features/space_references/domain/space_reference_type_group.dart';

enum SpaceReferenceType {
  apartamento(
    apiValue: 'APARTAMENTO',
    label: 'Apartamento',
    group: SpaceReferenceTypeGroup.residencial,
  ),
  casa(
    apiValue: 'CASA',
    label: 'Casa',
    group: SpaceReferenceTypeGroup.residencial,
  ),
  chacara(
    apiValue: 'CHACARA',
    label: 'Chácara',
    group: SpaceReferenceTypeGroup.residencial,
  ),
  fazenda(
    apiValue: 'FAZENDA',
    label: 'Fazenda',
    group: SpaceReferenceTypeGroup.residencial,
  ),
  sitio(
    apiValue: 'SITIO',
    label: 'Sítio',
    group: SpaceReferenceTypeGroup.residencial,
  ),
  terreno(
    apiValue: 'TERRENO',
    label: 'Terreno',
    group: SpaceReferenceTypeGroup.residencial,
  ),
  sobrado(
    apiValue: 'SOBRADO',
    label: 'Sobrado',
    group: SpaceReferenceTypeGroup.residencial,
  ),
  kitnet(
    apiValue: 'KITNET',
    label: 'Kitnet',
    group: SpaceReferenceTypeGroup.residencial,
  ),
  cobertura(
    apiValue: 'COBERTURA',
    label: 'Cobertura',
    group: SpaceReferenceTypeGroup.residencial,
  ),
  studioResidencial(
    apiValue: 'STUDIO_RESIDENCIAL',
    label: 'Studio residencial',
    group: SpaceReferenceTypeGroup.residencial,
  ),
  escritorio(
    apiValue: 'ESCRITORIO',
    label: 'Escritório',
    group: SpaceReferenceTypeGroup.comercialTrabalho,
  ),
  salaComercial(
    apiValue: 'SALA_COMERCIAL',
    label: 'Sala comercial',
    group: SpaceReferenceTypeGroup.comercialTrabalho,
  ),
  loja(
    apiValue: 'LOJA',
    label: 'Loja',
    group: SpaceReferenceTypeGroup.comercialTrabalho,
  ),
  galpao(
    apiValue: 'GALPAO',
    label: 'Galpão',
    group: SpaceReferenceTypeGroup.comercialTrabalho,
  ),
  estudio(
    apiValue: 'ESTUDIO',
    label: 'Estúdio',
    group: SpaceReferenceTypeGroup.comercialTrabalho,
  ),
  consultorio(
    apiValue: 'CONSULTORIO',
    label: 'Consultório',
    group: SpaceReferenceTypeGroup.comercialTrabalho,
  ),
  clinica(
    apiValue: 'CLINICA',
    label: 'Clínica',
    group: SpaceReferenceTypeGroup.comercialTrabalho,
  ),
  oficina(
    apiValue: 'OFICINA',
    label: 'Oficina',
    group: SpaceReferenceTypeGroup.comercialTrabalho,
  ),
  pontoComercial(
    apiValue: 'PONTO_COMERCIAL',
    label: 'Ponto comercial',
    group: SpaceReferenceTypeGroup.comercialTrabalho,
  ),
  coworking(
    apiValue: 'COWORKING',
    label: 'Coworking',
    group: SpaceReferenceTypeGroup.comercialTrabalho,
  ),
  deposito(
    apiValue: 'DEPOSITO',
    label: 'Depósito',
    group: SpaceReferenceTypeGroup.comercialTrabalho,
  ),
  trabalho(
    apiValue: 'TRABALHO',
    label: 'Trabalho',
    group: SpaceReferenceTypeGroup.comercialTrabalho,
  ),
  cliente(
    apiValue: 'CLIENTE',
    label: 'Cliente',
    group: SpaceReferenceTypeGroup.comercialTrabalho,
  ),
  projeto(
    apiValue: 'PROJETO',
    label: 'Projeto',
    group: SpaceReferenceTypeGroup.comercialTrabalho,
  ),
  contrato(
    apiValue: 'CONTRATO',
    label: 'Contrato',
    group: SpaceReferenceTypeGroup.comercialTrabalho,
  ),
  unidadeAtendimento(
    apiValue: 'UNIDADE_ATENDIMENTO',
    label: 'Unidade de atendimento',
    group: SpaceReferenceTypeGroup.comercialTrabalho,
  ),
  filial(
    apiValue: 'FILIAL',
    label: 'Filial',
    group: SpaceReferenceTypeGroup.comercialTrabalho,
  ),
  comercialOutro(
    apiValue: 'COMERCIAL_OUTRO',
    label: 'Outro comercial',
    group: SpaceReferenceTypeGroup.comercialTrabalho,
  ),
  carro(
    apiValue: 'CARRO',
    label: 'Carro',
    group: SpaceReferenceTypeGroup.veiculos,
  ),
  moto(
    apiValue: 'MOTO',
    label: 'Moto',
    group: SpaceReferenceTypeGroup.veiculos,
  ),
  caminhao(
    apiValue: 'CAMINHAO',
    label: 'Caminhão',
    group: SpaceReferenceTypeGroup.veiculos,
  ),
  van(apiValue: 'VAN', label: 'Van', group: SpaceReferenceTypeGroup.veiculos),
  utilitario(
    apiValue: 'UTILITARIO',
    label: 'Utilitário',
    group: SpaceReferenceTypeGroup.veiculos,
  ),
  lancha(
    apiValue: 'LANCHA',
    label: 'Lancha',
    group: SpaceReferenceTypeGroup.embarcacao,
  ),
  barco(
    apiValue: 'BARCO',
    label: 'Barco',
    group: SpaceReferenceTypeGroup.embarcacao,
  ),
  veleiro(
    apiValue: 'VELEIRO',
    label: 'Veleiro',
    group: SpaceReferenceTypeGroup.embarcacao,
  ),
  jetSki(
    apiValue: 'JET_SKI',
    label: 'Jet ski',
    group: SpaceReferenceTypeGroup.embarcacao,
  ),
  iate(
    apiValue: 'IATE',
    label: 'Iate',
    group: SpaceReferenceTypeGroup.embarcacao,
  ),
  marina(
    apiValue: 'MARINA',
    label: 'Marina',
    group: SpaceReferenceTypeGroup.embarcacao,
  ),
  embarcacaoOutro(
    apiValue: 'EMBARCACAO_OUTRO',
    label: 'Outra embarcação',
    group: SpaceReferenceTypeGroup.embarcacao,
  ),
  aviao(
    apiValue: 'AVIAO',
    label: 'Avião',
    group: SpaceReferenceTypeGroup.aviacao,
  ),
  helicoptero(
    apiValue: 'HELICOPTERO',
    label: 'Helicóptero',
    group: SpaceReferenceTypeGroup.aviacao,
  ),
  hangar(
    apiValue: 'HANGAR',
    label: 'Hangar',
    group: SpaceReferenceTypeGroup.aviacao,
  ),
  aviacaoOutro(
    apiValue: 'AVIACAO_OUTRO',
    label: 'Outra aviação',
    group: SpaceReferenceTypeGroup.aviacao,
  );

  const SpaceReferenceType({
    required this.apiValue,
    required this.label,
    required this.group,
  });

  final String apiValue;
  final String label;
  final SpaceReferenceTypeGroup group;

  static SpaceReferenceType fromApiValue(String value) {
    return values.firstWhere(
      (type) => type.apiValue == value,
      orElse: () => throw ArgumentError.value(
        value,
        'value',
        'Tipo de referência desconhecido.',
      ),
    );
  }

  static List<SpaceReferenceType> valuesForGroup(
    SpaceReferenceTypeGroup? group,
  ) {
    if (group == null) {
      return values;
    }
    return values.where((type) => type.group == group).toList();
  }
}
