import 'location_suggestion_model.dart';

class SocietySearchResultModel {
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
  final double distanceKm;
  final int availableSlots;
  final String startingHourlyRate;
  final String vehicleType;

  const SocietySearchResultModel({
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
    required this.distanceKm,
    required this.availableSlots,
    required this.startingHourlyRate,
    required this.vehicleType,
  });

  factory SocietySearchResultModel.fromJson(Map<String, dynamic> json) {
    return SocietySearchResultModel(
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
      distanceKm: _asDouble(json['distance_km']),
      availableSlots: _asInt(json['available_slots']),
      startingHourlyRate: json['starting_hourly_rate'] as String? ?? '0',
      vehicleType: json['vehicle_type'] as String? ?? '',
    );
  }
}

class SocietySearchResponseModel {
  final LocationSuggestionModel destination;
  final double searchRadiusKm;
  final List<SocietySearchResultModel> results;

  const SocietySearchResponseModel({
    required this.destination,
    required this.searchRadiusKm,
    required this.results,
  });

  factory SocietySearchResponseModel.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'] as List<dynamic>? ?? const [];
    return SocietySearchResponseModel(
      destination: LocationSuggestionModel.fromJson(
        json['destination'] as Map<String, dynamic>? ?? const {},
      ),
      searchRadiusKm: _asDouble(json['search_radius_km']),
      results: rawResults
          .map(
            (item) =>
                SocietySearchResultModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

double _asDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double? _asNullableDouble(Object? value) {
  if (value == null) {
    return null;
  }
  return _asDouble(value);
}

int _asInt(Object? value) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
