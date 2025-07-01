class RoleItem {
  final String userId;
  final String name;
  final String email;
  final String phoneNo;
  final String dateAdded;
  final String role;
  final bool isActive;
  final String? address;
  final String? profilePicture; // Added profile picture field

  RoleItem({
    required this.userId,
    required this.name,
    required this.email,
    required this.phoneNo,
    required this.dateAdded,
    required this.role,
    required this.isActive,
    this.address,
    this.profilePicture, // Added to constructor
  });

  RoleItem copyWith({
    String? userId,
    String? name,
    String? email,
    String? phoneNo,
    String? dateAdded,
    String? role,
    bool? isActive,
    String? address,
    String? profilePicture, // Added to copyWith
  }) {
    return RoleItem(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNo: phoneNo ?? this.phoneNo,
      dateAdded: dateAdded ?? this.dateAdded,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      address: address ?? this.address,
      profilePicture:
          profilePicture ?? this.profilePicture, // Added to copyWith
    );
  }
}
