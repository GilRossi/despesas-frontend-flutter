import 'package:despesas_frontend/features/space_references/domain/space_reference_create_result_type.dart';
import 'package:despesas_frontend/features/space_references/domain/space_reference_item.dart';

class SpaceReferenceCreateResult {
  const SpaceReferenceCreateResult({
    required this.result,
    this.reference,
    this.suggestedReference,
    this.message,
  });

  final SpaceReferenceCreateResultType result;
  final SpaceReferenceItem? reference;
  final SpaceReferenceItem? suggestedReference;
  final String? message;

  bool get isCreated => result == SpaceReferenceCreateResultType.created;
  bool get isDuplicateSuggestion =>
      result == SpaceReferenceCreateResultType.duplicateSuggestion;

  factory SpaceReferenceCreateResult.fromJson(Map<String, dynamic> json) {
    return SpaceReferenceCreateResult(
      result: SpaceReferenceCreateResultType.fromApiValue(
        json['result'] as String? ?? '',
      ),
      reference: json['reference'] is Map<String, dynamic>
          ? SpaceReferenceItem.fromJson(
              json['reference'] as Map<String, dynamic>,
            )
          : null,
      suggestedReference: json['suggestedReference'] is Map<String, dynamic>
          ? SpaceReferenceItem.fromJson(
              json['suggestedReference'] as Map<String, dynamic>,
            )
          : null,
      message: json['message'] as String?,
    );
  }
}
