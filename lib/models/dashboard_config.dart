import 'dart:convert';

enum DashboardSection {
  totalBalance('Total Balance'),
  quickActions('Quick Actions'),
  budgetStatus('Budget Status'),
  incomeExpenseChart('Income vs Expenses'),
  overviewCards('Overview'),
  recentTransactions('Recent Transactions'),
  savingsGoals('Savings Goals');

  const DashboardSection(this.label);
  final String label;
}

class DashboardSectionConfig {
  final DashboardSection section;
  final bool isVisible;

  const DashboardSectionConfig({
    required this.section,
    required this.isVisible,
  });

  DashboardSectionConfig copyWith({bool? isVisible}) {
    return DashboardSectionConfig(
      section: section,
      isVisible: isVisible ?? this.isVisible,
    );
  }

  Map<String, dynamic> toJson() => {
        'section': section.name,
        'isVisible': isVisible,
      };

  factory DashboardSectionConfig.fromJson(Map<String, dynamic> json) {
    return DashboardSectionConfig(
      section: DashboardSection.values.firstWhere(
        (s) => s.name == json['section'],
        orElse: () => DashboardSection.totalBalance,
      ),
      isVisible: json['isVisible'] as bool? ?? true,
    );
  }
}

class DashboardConfig {
  final List<DashboardSectionConfig> sections;

  const DashboardConfig({required this.sections});

  factory DashboardConfig.defaultConfig() {
    return DashboardConfig(
      sections: DashboardSection.values
          .map((s) => DashboardSectionConfig(section: s, isVisible: true))
          .toList(),
    );
  }

  DashboardConfig copyWith({List<DashboardSectionConfig>? sections}) {
    return DashboardConfig(sections: sections ?? this.sections);
  }

  String toJsonString() => jsonEncode(
        sections.map((s) => s.toJson()).toList(),
      );

  factory DashboardConfig.fromJsonString(String jsonString) {
    final List<dynamic> decoded = jsonDecode(jsonString);
    final configs = decoded
        .map((e) => DashboardSectionConfig.fromJson(e as Map<String, dynamic>))
        .toList();

    // Forward-compatibility: append any new enum values not in saved config
    final savedSections = configs.map((c) => c.section).toSet();
    for (final section in DashboardSection.values) {
      if (!savedSections.contains(section)) {
        configs.add(DashboardSectionConfig(section: section, isVisible: true));
      }
    }

    return DashboardConfig(sections: configs);
  }

  List<DashboardSection> get visibleSections =>
      sections.where((s) => s.isVisible).map((s) => s.section).toList();
}
