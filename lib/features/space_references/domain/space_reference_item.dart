import 'package:despesas_frontend/features/space_references/domain/space_reference_type.dart';
import 'package:despesas_frontend/features/space_references/domain/space_reference_type_group.dart';

class SpaceReferenceItem {
  const SpaceReferenceItem({
    required this.id,
    required this.type,
    required this.typeGroup,
    required this.name,
  });

  final int id;
  final SpaceReferenceType type;
  final SpaceReferenceTypeGroup typeGroup;
  final String name;

  factory SpaceReferenceItem.fromJson(Map<String, dynamic> json) {
    return SpaceReferenceItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: SpaceReferenceType.fromApiValue(json['type'] as String? ?? ''),
      typeGroup: SpaceReferenceTypeGroup.fromApiValue(
        json['typeGroup'] as String? ?? '',
      ),
      name: json['name'] as String? ?? '',
    );
  }
}
