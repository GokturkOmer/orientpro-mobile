class BadgeCatalogItem {
  final String code;
  final String name;
  final String description;
  final String icon;
  final String level;

  BadgeCatalogItem({required this.code, required this.name, required this.description, required this.icon, required this.level});

  factory BadgeCatalogItem.fromJson(Map<String, dynamic> json) {
    return BadgeCatalogItem(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
      level: json['level'] ?? 'bronze',
    );
  }
}

class UserBadge {
  final String id;
  final String badgeCode;
  final String badgeName;
  final String? badgeDescription;
  final String? badgeIcon;
  final String badgeLevel;
  final String? earnedAt;

  UserBadge({required this.id, required this.badgeCode, required this.badgeName, this.badgeDescription, this.badgeIcon, required this.badgeLevel, this.earnedAt});

  factory UserBadge.fromJson(Map<String, dynamic> json) {
    return UserBadge(
      id: json['id'] ?? '',
      badgeCode: json['badge_code'] ?? '',
      badgeName: json['badge_name'] ?? '',
      badgeDescription: json['badge_description'],
      badgeIcon: json['badge_icon'],
      badgeLevel: json['badge_level'] ?? 'bronze',
      earnedAt: json['earned_at'],
    );
  }
}

class BadgeCheckResult {
  final List<Map<String, dynamic>> newlyAwarded;
  final int totalBadges;

  BadgeCheckResult({required this.newlyAwarded, required this.totalBadges});

  factory BadgeCheckResult.fromJson(Map<String, dynamic> json) {
    return BadgeCheckResult(
      newlyAwarded: (json['newly_awarded'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [],
      totalBadges: json['total_badges'] ?? 0,
    );
  }
}
