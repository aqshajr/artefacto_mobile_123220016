import 'temple_model.dart';

class TempleSummary {
  String? templeName;
  String? location;

  TempleSummary({this.templeName, this.location});

  factory TempleSummary.fromJson(Map<String, dynamic> json) {
    return TempleSummary(
      templeName: json['templeName'] ?? json['title'], // Fallback ke 'title' dari TempleModel
      location: json['location'] ?? json['locationUrl'], // Fallback ke 'locationUrl' dari TempleModel
    );
  }

  // Constructor dari TempleModel
  factory TempleSummary.fromTempleModel(Temple temple) {
    return TempleSummary(
      templeName: temple.title, // Menggunakan title dari Temple sebagai templeName
      location: temple.locationUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'templeName': templeName,
      'location': location,
    };
  }
}