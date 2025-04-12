class RoleItem {
  final String userId;
  final String name;
  final String email;
  final String phoneNo;
  final String dateAdded;
  final String role;
  final String? address;

  RoleItem({
    required this.userId,
    required this.name,
    required this.email,
    required this.phoneNo,
    required this.dateAdded,
    required this.role,
    this.address,
  });

  RoleItem copyWith({
    String? userId,
    String? name,
    String? email,
    String? phoneNo,
    String? dateAdded,
    String? role,
    String? address,
  }) {
    return RoleItem(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNo: phoneNo ?? this.phoneNo,
      dateAdded: dateAdded ?? this.dateAdded,
      role: role ?? this.role,
      address: address ?? this.address,
    );
  }
}
