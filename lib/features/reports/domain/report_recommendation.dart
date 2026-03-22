class ReportRecommendation {
  const ReportRecommendation({
    required this.title,
    required this.rationale,
    required this.action,
  });

  final String title;
  final String rationale;
  final String action;

  factory ReportRecommendation.fromJson(Map<String, dynamic> json) {
    return ReportRecommendation(
      title: json['title'] as String? ?? '',
      rationale: json['rationale'] as String? ?? '',
      action: json['action'] as String? ?? '',
    );
  }
}
