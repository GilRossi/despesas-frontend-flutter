import 'package:despesas_frontend/features/reports/domain/report_category_total.dart';
import 'package:despesas_frontend/features/reports/domain/report_month_comparison.dart';
import 'package:despesas_frontend/features/space_references/domain/space_reference_type_group.dart';

class DashboardSummary {
  const DashboardSummary({
    required this.role,
    required this.summaryMain,
    required this.actionNeeded,
    required this.recentActivity,
    required this.assistantCard,
    this.monthOverview,
    this.categorySpending,
    this.householdSummary,
    this.quickActions,
  });

  final String role;
  final DashboardSummaryMain summaryMain;
  final DashboardActionNeeded actionNeeded;
  final DashboardRecentActivity recentActivity;
  final DashboardAssistantCard assistantCard;
  final DashboardMonthOverview? monthOverview;
  final DashboardCategorySpending? categorySpending;
  final DashboardHouseholdSummary? householdSummary;
  final DashboardQuickActions? quickActions;

  bool get isOwner => role == 'OWNER';
  bool get isMember => role == 'MEMBER';

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      role: json['role'] as String? ?? '',
      summaryMain: DashboardSummaryMain.fromJson(
        json['summaryMain'] as Map<String, dynamic>? ?? const {},
      ),
      actionNeeded: DashboardActionNeeded.fromJson(
        json['actionNeeded'] as Map<String, dynamic>? ?? const {},
      ),
      recentActivity: DashboardRecentActivity.fromJson(
        json['recentActivity'] as Map<String, dynamic>? ?? const {},
      ),
      assistantCard: DashboardAssistantCard.fromJson(
        json['assistantCard'] as Map<String, dynamic>? ?? const {},
      ),
      monthOverview: _mapOrNull(
        json['monthOverview'],
        (value) => DashboardMonthOverview.fromJson(value),
      ),
      categorySpending: _mapOrNull(
        json['categorySpending'],
        (value) => DashboardCategorySpending.fromJson(value),
      ),
      householdSummary: _mapOrNull(
        json['householdSummary'],
        (value) => DashboardHouseholdSummary.fromJson(value),
      ),
      quickActions: _mapOrNull(
        json['quickActions'],
        (value) => DashboardQuickActions.fromJson(value),
      ),
    );
  }

  static T? _mapOrNull<T>(
    Object? value,
    T Function(Map<String, dynamic> map) mapper,
  ) {
    if (value is! Map<String, dynamic>) {
      return null;
    }
    return mapper(value);
  }
}

class DashboardSummaryMain {
  const DashboardSummaryMain({
    required this.referenceMonth,
    required this.totalOpenAmount,
    required this.totalOverdueAmount,
    required this.paidThisMonthAmount,
    required this.openCount,
    required this.overdueCount,
  });

  final String referenceMonth;
  final double totalOpenAmount;
  final double totalOverdueAmount;
  final double paidThisMonthAmount;
  final int openCount;
  final int overdueCount;

  factory DashboardSummaryMain.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryMain(
      referenceMonth: json['referenceMonth'] as String? ?? '',
      totalOpenAmount: _toDouble(json['totalOpenAmount']),
      totalOverdueAmount: _toDouble(json['totalOverdueAmount']),
      paidThisMonthAmount: _toDouble(json['paidThisMonthAmount']),
      openCount: _toInt(json['openCount']),
      overdueCount: _toInt(json['overdueCount']),
    );
  }
}

class DashboardActionNeeded {
  const DashboardActionNeeded({
    required this.overdueCount,
    required this.overdueAmount,
    required this.openCount,
    required this.openAmount,
    required this.items,
  });

  final int overdueCount;
  final double overdueAmount;
  final int openCount;
  final double openAmount;
  final List<DashboardActionItem> items;

  factory DashboardActionNeeded.fromJson(Map<String, dynamic> json) {
    return DashboardActionNeeded(
      overdueCount: _toInt(json['overdueCount']),
      overdueAmount: _toDouble(json['overdueAmount']),
      openCount: _toInt(json['openCount']),
      openAmount: _toDouble(json['openAmount']),
      items: (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(DashboardActionItem.fromJson)
          .toList(),
    );
  }
}

class DashboardActionItem {
  const DashboardActionItem({
    required this.expenseId,
    required this.description,
    required this.dueDate,
    required this.status,
    required this.amount,
    required this.route,
  });

  final int expenseId;
  final String description;
  final DateTime? dueDate;
  final String status;
  final double amount;
  final String route;

  factory DashboardActionItem.fromJson(Map<String, dynamic> json) {
    return DashboardActionItem(
      expenseId: _toInt(json['expenseId']),
      description: json['description'] as String? ?? '',
      dueDate: _toDateTime(json['dueDate']),
      status: json['status'] as String? ?? '',
      amount: _toDouble(json['amount']),
      route: json['route'] as String? ?? '/expenses',
    );
  }
}

class DashboardRecentActivity {
  const DashboardRecentActivity({required this.items});

  final List<DashboardRecentActivityItem> items;

  factory DashboardRecentActivity.fromJson(Map<String, dynamic> json) {
    return DashboardRecentActivity(
      items: (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(DashboardRecentActivityItem.fromJson)
          .toList(),
    );
  }
}

class DashboardRecentActivityItem {
  const DashboardRecentActivityItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.occurredAt,
    required this.route,
  });

  final String type;
  final String title;
  final String subtitle;
  final double amount;
  final DateTime? occurredAt;
  final String route;

  factory DashboardRecentActivityItem.fromJson(Map<String, dynamic> json) {
    return DashboardRecentActivityItem(
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      amount: _toDouble(json['amount']),
      occurredAt: _toDateTime(json['occurredAt']),
      route: json['route'] as String? ?? '/expenses',
    );
  }
}

class DashboardAssistantCard {
  const DashboardAssistantCard({
    required this.title,
    required this.message,
    required this.primaryActionKey,
    required this.route,
  });

  final String title;
  final String message;
  final String primaryActionKey;
  final String route;

  factory DashboardAssistantCard.fromJson(Map<String, dynamic> json) {
    return DashboardAssistantCard(
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      primaryActionKey: json['primaryActionKey'] as String? ?? '',
      route: json['route'] as String? ?? '/assistant',
    );
  }
}

class DashboardMonthOverview {
  const DashboardMonthOverview({
    required this.referenceMonth,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.monthComparison,
    required this.highestSpendingCategory,
  });

  final String referenceMonth;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final ReportMonthComparison? monthComparison;
  final DashboardHighestSpendingCategory? highestSpendingCategory;

  factory DashboardMonthOverview.fromJson(Map<String, dynamic> json) {
    return DashboardMonthOverview(
      referenceMonth: json['referenceMonth'] as String? ?? '',
      totalAmount: _toDouble(json['totalAmount']),
      paidAmount: _toDouble(json['paidAmount']),
      remainingAmount: _toDouble(json['remainingAmount']),
      monthComparison: json['monthComparison'] is Map<String, dynamic>
          ? ReportMonthComparison.fromJson(
              json['monthComparison'] as Map<String, dynamic>,
            )
          : null,
      highestSpendingCategory:
          json['highestSpendingCategory'] is Map<String, dynamic>
          ? DashboardHighestSpendingCategory.fromJson(
              json['highestSpendingCategory'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class DashboardHighestSpendingCategory {
  const DashboardHighestSpendingCategory({
    required this.categoryId,
    required this.categoryName,
    required this.totalAmount,
    required this.sharePercentage,
  });

  final int categoryId;
  final String categoryName;
  final double totalAmount;
  final double sharePercentage;

  factory DashboardHighestSpendingCategory.fromJson(
    Map<String, dynamic> json,
  ) {
    return DashboardHighestSpendingCategory(
      categoryId: _toInt(json['categoryId']),
      categoryName: json['categoryName'] as String? ?? '',
      totalAmount: _toDouble(json['totalAmount']),
      sharePercentage: _toDouble(json['sharePercentage']),
    );
  }
}

class DashboardCategorySpending {
  const DashboardCategorySpending({required this.items});

  final List<ReportCategoryTotal> items;

  factory DashboardCategorySpending.fromJson(Map<String, dynamic> json) {
    return DashboardCategorySpending(
      items: (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ReportCategoryTotal.fromJson)
          .toList(),
    );
  }
}

class DashboardHouseholdSummary {
  const DashboardHouseholdSummary({
    required this.membersCount,
    required this.ownersCount,
    required this.membersOnlyCount,
    required this.spaceReferencesCount,
    required this.referencesByGroup,
  });

  final int membersCount;
  final int ownersCount;
  final int membersOnlyCount;
  final int spaceReferencesCount;
  final List<DashboardReferenceGroupSummary> referencesByGroup;

  factory DashboardHouseholdSummary.fromJson(Map<String, dynamic> json) {
    return DashboardHouseholdSummary(
      membersCount: _toInt(json['membersCount']),
      ownersCount: _toInt(json['ownersCount']),
      membersOnlyCount: _toInt(json['membersOnlyCount']),
      spaceReferencesCount: _toInt(json['spaceReferencesCount']),
      referencesByGroup: (json['referencesByGroup'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(DashboardReferenceGroupSummary.fromJson)
          .toList(),
    );
  }
}

class DashboardReferenceGroupSummary {
  const DashboardReferenceGroupSummary({
    required this.group,
    required this.count,
  });

  final SpaceReferenceTypeGroup group;
  final int count;

  factory DashboardReferenceGroupSummary.fromJson(Map<String, dynamic> json) {
    return DashboardReferenceGroupSummary(
      group: SpaceReferenceTypeGroup.fromApiValue(
        json['group'] as String? ?? 'RESIDENCIAL',
      ),
      count: _toInt(json['count']),
    );
  }
}

class DashboardQuickActions {
  const DashboardQuickActions({required this.items});

  final List<DashboardQuickActionItem> items;

  factory DashboardQuickActions.fromJson(Map<String, dynamic> json) {
    return DashboardQuickActions(
      items: (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(DashboardQuickActionItem.fromJson)
          .toList(),
    );
  }
}

class DashboardQuickActionItem {
  const DashboardQuickActionItem({
    required this.key,
    required this.label,
    required this.route,
  });

  final String key;
  final String label;
  final String route;

  factory DashboardQuickActionItem.fromJson(Map<String, dynamic> json) {
    return DashboardQuickActionItem(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      route: json['route'] as String? ?? '/',
    );
  }
}

int _toInt(Object? value) {
  return switch (value) {
    int number => number,
    double number => number.toInt(),
    String number => int.tryParse(number) ?? 0,
    _ => 0,
  };
}

double _toDouble(Object? value) {
  return switch (value) {
    int number => number.toDouble(),
    double number => number,
    String number => double.tryParse(number) ?? 0,
    _ => 0,
  };
}

DateTime? _toDateTime(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}
