class DeliveryPerson {
  final int id;
  final String name;
  final String email;
  final String? profileImage;
  final String? phoneNumber;

  DeliveryPerson({
    required this.id,
    required this.name,
    required this.email,
    this.profileImage,
    this.phoneNumber,
  });

  factory DeliveryPerson.fromJson(Map<String, dynamic> json) {
    return DeliveryPerson(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profileImage: json['profilePicture'],
      phoneNumber: json['phoneNumber'],
    );
  }
}
