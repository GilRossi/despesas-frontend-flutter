import 'dart:convert';

import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/network/authorized_request_executor.dart';
import 'package:despesas_frontend/core/network/despesas_api_client.dart';
import 'package:despesas_frontend/features/auth/domain/auth_onboarding.dart';
import 'package:despesas_frontend/features/space_references/data/http_space_references_repository.dart';
import 'package:despesas_frontend/features/space_references/domain/create_space_reference_input.dart';
import 'package:despesas_frontend/features/space_references/domain/space_reference_create_result_type.dart';
import 'package:despesas_frontend/features/space_references/domain/space_reference_type.dart';
import 'package:despesas_frontend/features/space_references/domain/space_reference_type_group.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../../support/test_doubles.dart';

void main() {
  test(
    'listReferences envia filtros autenticados e interpreta a lista',
    () async {
      late http.Request capturedRequest;
      final client = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 7,
                'type': 'CLIENTE',
                'typeGroup': 'COMERCIAL_TRABALHO',
                'name': 'Projeto Acme',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final sessionController = SessionController(
        authRepository: FakeAuthRepository(
          loginResult: fakeSession(
            onboarding: const AuthOnboarding(completed: false),
          ),
        ),
        sessionStore: MemorySessionStore(),
      );
      await sessionController.login(
        email: 'gil@example.com',
        password: 'Senha123!',
      );
      final repository = HttpSpaceReferencesRepository(
        AuthorizedRequestExecutor(
          apiClient: DespesasApiClient(
            baseUrl: Uri.parse('https://app.rossicompany.com.br/'),
            httpClient: client,
          ),
          sessionManager: sessionController,
        ),
      );

      final references = await repository.listReferences(
        typeGroup: SpaceReferenceTypeGroup.comercialTrabalho,
        query: 'projeto',
      );

      expect(
        capturedRequest.url.toString(),
        'https://app.rossicompany.com.br/api/v1/space/references?typeGroup=COMERCIAL_TRABALHO&q=projeto',
      );
      expect(capturedRequest.headers['authorization'], 'Bearer access-token');
      expect(references.single.name, 'Projeto Acme');
      expect(references.single.type, SpaceReferenceType.cliente);
    },
  );

  test(
    'createReference interpreta DUPLICATE_SUGGESTION sem tratar como erro',
    () async {
      late http.Request capturedRequest;
      final client = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'data': {
              'result': 'DUPLICATE_SUGGESTION',
              'reference': null,
              'suggestedReference': {
                'id': 9,
                'type': 'CLIENTE',
                'typeGroup': 'COMERCIAL_TRABALHO',
                'name': 'Projeto Acme',
              },
              'message':
                  'Encontrei uma referencia parecida no seu Espaco. Quer usar essa para evitar duplicidade?',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final sessionController = SessionController(
        authRepository: FakeAuthRepository(
          loginResult: fakeSession(
            onboarding: const AuthOnboarding(completed: false),
          ),
        ),
        sessionStore: MemorySessionStore(),
      );
      await sessionController.login(
        email: 'gil@example.com',
        password: 'Senha123!',
      );
      final repository = HttpSpaceReferencesRepository(
        AuthorizedRequestExecutor(
          apiClient: DespesasApiClient(
            baseUrl: Uri.parse('https://app.rossicompany.com.br/'),
            httpClient: client,
          ),
          sessionManager: sessionController,
        ),
      );

      final result = await repository.createReference(
        const CreateSpaceReferenceInput(
          type: SpaceReferenceType.cliente,
          name: 'Projeto Acme',
        ),
      );

      expect(
        capturedRequest.url.toString(),
        'https://app.rossicompany.com.br/api/v1/space/references',
      );
      expect(jsonDecode(capturedRequest.body), {
        'type': 'CLIENTE',
        'name': 'Projeto Acme',
      });
      expect(result.result, SpaceReferenceCreateResultType.duplicateSuggestion);
      expect(result.suggestedReference?.name, 'Projeto Acme');
    },
  );
}
