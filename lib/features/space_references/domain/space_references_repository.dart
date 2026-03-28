import 'package:despesas_frontend/features/space_references/domain/create_space_reference_input.dart';
import 'package:despesas_frontend/features/space_references/domain/space_reference_create_result.dart';
import 'package:despesas_frontend/features/space_references/domain/space_reference_item.dart';
import 'package:despesas_frontend/features/space_references/domain/space_reference_type.dart';
import 'package:despesas_frontend/features/space_references/domain/space_reference_type_group.dart';

abstract interface class SpaceReferencesRepository {
  Future<List<SpaceReferenceItem>> listReferences({
    SpaceReferenceTypeGroup? typeGroup,
    SpaceReferenceType? type,
    String? query,
  });

  Future<SpaceReferenceCreateResult> createReference(
    CreateSpaceReferenceInput input,
  );
}
