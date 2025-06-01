class DeliveryPerson {
  final int userId;
  final String email;
  final String roleName;
  final String? profilePicture;
  final String name;

  DeliveryPerson({
    required this.userId,
    required this.email,
    required this.roleName,
    this.profilePicture,
    required this.name,
  });

  factory DeliveryPerson.fromJson(Map<String, dynamic> json) {
    return DeliveryPerson(
      userId: json['userId'] as int,
      email: json['email'] as String,
      roleName: json['roleName'] as String,
      profilePicture: json['profilePicture'] as String?,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'roleName': roleName,
      'profilePicture': profilePicture,
      'name': name,
    };
  }
}
