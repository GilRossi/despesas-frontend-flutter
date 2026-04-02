import 'package:despesas_frontend/features/space_references/domain/space_reference_create_result_type.dart';
import 'package:despesas_frontend/features/space_references/domain/space_reference_type.dart';
import 'package:despesas_frontend/features/space_references/domain/space_reference_type_group.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mantem labels de referencias com acentuacao pt-br', () {
    expect(SpaceReferenceTypeGroup.veiculos.label, 'Veículos');
    expect(SpaceReferenceTypeGroup.embarcacao.label, 'Embarcação');
    expect(SpaceReferenceTypeGroup.aviacao.label, 'Aviação');

    expect(SpaceReferenceType.chacara.label, 'Chácara');
    expect(SpaceReferenceType.sitio.label, 'Sítio');
    expect(SpaceReferenceType.escritorio.label, 'Escritório');
    expect(SpaceReferenceType.galpao.label, 'Galpão');
    expect(SpaceReferenceType.estudio.label, 'Estúdio');
    expect(SpaceReferenceType.consultorio.label, 'Consultório');
    expect(SpaceReferenceType.clinica.label, 'Clínica');
    expect(SpaceReferenceType.deposito.label, 'Depósito');
    expect(SpaceReferenceType.caminhao.label, 'Caminhão');
    expect(SpaceReferenceType.utilitario.label, 'Utilitário');
    expect(SpaceReferenceType.embarcacaoOutro.label, 'Outra embarcação');
    expect(SpaceReferenceType.aviao.label, 'Avião');
    expect(SpaceReferenceType.helicoptero.label, 'Helicóptero');
    expect(SpaceReferenceType.aviacaoOutro.label, 'Outra aviação');
  });

  test('mensagens de fallback preservam referencia e criacao com acento', () {
    expect(
      () => SpaceReferenceCreateResultType.fromApiValue('INVALID'),
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.message,
          'message',
          contains('Resultado de criação desconhecido.'),
        ),
      ),
    );

    expect(
      () => SpaceReferenceTypeGroup.fromApiValue('INVALID'),
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.message,
          'message',
          contains('Grupo de referência desconhecido.'),
        ),
      ),
    );

    expect(
      () => SpaceReferenceType.fromApiValue('INVALID'),
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.message,
          'message',
          contains('Tipo de referência desconhecido.'),
        ),
      ),
    );
  });
}
