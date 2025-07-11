// lib/models/profile.dart

class ProfileStats {
  final int totalDeliveries;
  final double totalRevenue;
  final int avgDeliveryTime;
  final int uniqueCustomers;
  final int todayDeliveries;
  final int activeOrdersCount;

  ProfileStats({
    required this.totalDeliveries,
    required this.totalRevenue,
    required this.avgDeliveryTime,
    required this.uniqueCustomers,
    required this.todayDeliveries,
    required this.activeOrdersCount,
  });

  factory ProfileStats.fromJson(Map<String, dynamic> json) {
    return ProfileStats(
      totalDeliveries: (json['totalDeliveries'] ?? 0).toInt(),
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      avgDeliveryTime: (json['avgDeliveryTime'] ?? 0).toInt(),
      uniqueCustomers: (json['uniqueCustomers'] ?? 0).toInt(),
      todayDeliveries: (json['todayDeliveries'] ?? 0).toInt(),
      activeOrdersCount: (json['activeOrdersCount'] ?? 0).toInt(),
    );
  }
}

class ProfileUser {
  final int userId;
  final String name;
  final String email;
  final String phoneNumber;
  final String? profilePicture;

  ProfileUser({
    required this.userId,
    required this.name,
    required this.email,
    required this.phoneNumber,
    this.profilePicture,
  });

  factory ProfileUser.fromJson(Map<String, dynamic> json) {
    return ProfileUser(
      userId: json['userId'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String,
      profilePicture: json['profilePicture'] as String?,
    );
  }
}

class DeliveryProfile {
  final int id;
  final int userId;
  final String currentLatitude;
  final String currentLongitude;
  final bool isAvailable;
  final DateTime lastLocationUpdate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ProfileUser user;
  final ProfileStats stats;

  DeliveryProfile({
    required this.id,
    required this.userId,
    required this.currentLatitude,
    required this.currentLongitude,
    required this.isAvailable,
    required this.lastLocationUpdate,
    required this.createdAt,
    required this.updatedAt,
    required this.user,
    required this.stats,
  });

  factory DeliveryProfile.fromJson(Map<String, dynamic> json) {
    return DeliveryProfile(
      id: json['id'] as int,
      userId: json['userId'] as int,
      currentLatitude: json['currentLatitude'] as String,
      currentLongitude: json['currentLongitude'] as String,
      isAvailable: json['isAvailable'] as bool,
      lastLocationUpdate: DateTime.parse(json['lastLocationUpdate']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      user: ProfileUser.fromJson(json['user']),
      stats: ProfileStats.fromJson(json['stats']),
    );
  }
}

class ProfileResponse {
  final DeliveryProfile profile;

  ProfileResponse({required this.profile});

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    return ProfileResponse(
      profile: DeliveryProfile.fromJson(json['profile']),
    );
  }
}
