import 'package:despesas_frontend/features/space_references/domain/space_reference_type.dart';

class CreateSpaceReferenceInput {
  const CreateSpaceReferenceInput({required this.type, required this.name});

  final SpaceReferenceType type;
  final String name;
}
