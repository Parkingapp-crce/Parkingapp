class SocietyModel {
  final String id;
  final String name;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final double? latitude;
  final double? longitude;
  final String contactEmail;
  final String contactPhone;
  final bool isActive;
  final int? totalSlots;
  final int? availableSlots;
  final String createdAt;

  const SocietyModel({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    this.latitude,
    this.longitude,
    required this.contactEmail,
    required this.contactPhone,
    this.isActive = true,
    this.totalSlots,
    this.availableSlots,
    required this.createdAt,
  });

  factory SocietyModel.fromJson(Map<String, dynamic> json) {
    return SocietyModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      pincode: json['pincode'] as String? ?? '',
      latitude: _asNullableDouble(json['latitude']),
      longitude: _asNullableDouble(json['longitude']),
      contactEmail: json['contact_email'] as String? ?? '',
      contactPhone: json['contact_phone'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      totalSlots: _asNullableInt(json['total_slots']),
      availableSlots: _asNullableInt(json['available_slots']),
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'city': city,
    'state': state,
    'pincode': pincode,
    'latitude': latitude,
    'longitude': longitude,
    'contact_email': contactEmail,
    'contact_phone': contactPhone,
    'is_active': isActive,
    'total_slots': totalSlots,
    'available_slots': availableSlots,
    'created_at': createdAt,
  };
}

double? _asNullableDouble(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}

int? _asNullableInt(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value.toString());
}
