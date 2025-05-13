enum OrderStatus { pending, accepted, inProgress, delivered, cancelled }

class Order {
  final int id;
  final String customerName;
  final String address;
  final double latitude;
  final double longitude;
  final double amount;
  final String? notes;
  final DateTime createdAt;
  final OrderStatus status;

  Order({
    required this.id,
    required this.customerName,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.amount,
    this.notes,
    required this.createdAt,
    required this.status,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      customerName: json['customerName'] ?? 'Customer',
      address: json['address'] ?? '',
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      amount: double.parse(json['amount'].toString()),
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      status: _parseStatus(json['status']),
    );
  }

  static OrderStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'accepted':
        return OrderStatus.accepted;
      case 'in_progress':
        return OrderStatus.inProgress;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'pending':
      default:
        return OrderStatus.pending;
    }
  }
}
