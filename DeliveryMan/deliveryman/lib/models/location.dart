class DeliveryLocation {
  final double latitude;
  final double longitude;

  DeliveryLocation({
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
