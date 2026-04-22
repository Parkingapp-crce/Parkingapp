class LocationSuggestionModel {
  final String placeId;
  final String title;
  final String subtitle;
  final String label;
  final double latitude;
  final double longitude;

  const LocationSuggestionModel({
    required this.placeId,
    required this.title,
    required this.subtitle,
    required this.label,
    required this.latitude,
    required this.longitude,
  });

  factory LocationSuggestionModel.fromJson(Map<String, dynamic> json) {
    return LocationSuggestionModel(
      placeId: json['place_id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      label: json['label'] as String? ?? '',
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
    );
  }
}

double _asDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
