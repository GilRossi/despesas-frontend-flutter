import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/features/household_members/domain/create_household_member_input.dart';
import 'package:despesas_frontend/features/household_members/presentation/household_members_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_doubles.dart';

void main() {
  test('loads current household members', () async {
    final repository = FakeHouseholdMembersRepository(
      members: [
        fakeHouseholdMember(name: 'Gil Rossi', role: 'OWNER'),
        fakeHouseholdMember(
          id: 2,
          userId: 2,
          name: 'Bia Rossi',
          email: 'bia@example.com',
          role: 'MEMBER',
        ),
      ],
    );
    final viewModel = HouseholdMembersViewModel(
      householdMembersRepository: repository,
    );

    await viewModel.load();

    expect(repository.listCalls, 1);
    expect(viewModel.members.length, 2);
    expect(viewModel.members.last.name, 'Bia Rossi');
    expect(viewModel.loadErrorMessage, isNull);
  });

  test('creates member and reloads the list', () async {
    final repository = FakeHouseholdMembersRepository(
      members: [fakeHouseholdMember()],
    );
    final viewModel = HouseholdMembersViewModel(
      householdMembersRepository: repository,
    );

    final created = await viewModel.createMember(
      const CreateHouseholdMemberInput(
        name: 'Bia Rossi',
        email: 'bia@example.com',
        password: 'Senha123!',
      ),
    );

    expect(created, isTrue);
    expect(repository.createCalls, 1);
    expect(repository.listCalls, 1);
    expect(viewModel.members.length, 2);
    expect(viewModel.members.last.email, 'bia@example.com');
  });

  test('exposes submit errors and field errors', () async {
    final repository = FakeHouseholdMembersRepository(
      createError: const ApiException(
        statusCode: 422,
        message: 'Dados invalidos',
        fieldErrors: {'email': 'email must be valid'},
      ),
    );
    final viewModel = HouseholdMembersViewModel(
      householdMembersRepository: repository,
    );

    final created = await viewModel.createMember(
      const CreateHouseholdMemberInput(
        name: 'Bia Rossi',
        email: 'email-invalido',
        password: 'Senha123!',
      ),
    );

    expect(created, isFalse);
    expect(viewModel.submitErrorMessage, 'Dados invalidos');
    expect(viewModel.fieldError('email'), 'email must be valid');
  });
}
