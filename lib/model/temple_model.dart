class TempleModel {
  String? status;
  String? message;
  DataTemples? data;

  TempleModel({this.status, this.message, this.data});

  factory TempleModel.fromJson(Map<String, dynamic> json) {
    return TempleModel(
      status: json['status'],
      message: json['message'],
      data: json['data'] != null ? DataTemples.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'status': status, 'message': message, 'data': data?.toJson()};
  }
}

class DataTemples {
  List<Temple>? temples;

  DataTemples({this.temples});

  factory DataTemples.fromJson(Map<String, dynamic> json) {
    return DataTemples(
      temples: json['temples'] != null
          ? List<Temple>.from(
              json['temples'].map((x) => Temple.fromJson(x)),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'temples': temples?.map((x) => x.toJson()).toList()};
  }
}

class Temple {
  int? templeID;
  String? imageUrl;
  String? title;
  String? description;
  String? funfactTitle;
  String? funfactDescription;
  String? locationUrl;
  String? location;
  double? latitude;
  double? longitude;

  Temple({
    this.templeID,
    this.imageUrl,
    this.title,
    this.description,
    this.funfactTitle,
    this.funfactDescription,
    this.locationUrl,
    this.location,
    this.latitude,
    this.longitude,
  });

  String? get templeName => title;

  factory Temple.fromJson(Map<String, dynamic> json) {
    return Temple(
      templeID: json['templeID'],
      imageUrl: json['imageUrl'],
      title: json['title'],
      description: json['description'],
      funfactTitle: json['funfactTitle'],
      funfactDescription: json['funfactDescription'],
      locationUrl: json['locationUrl'],
      location: json['location'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'templeID': templeID,
      'imageUrl': imageUrl,
      'title': title,
      'description': description,
      'funfactTitle': funfactTitle,
      'funfactDescription': funfactDescription,
      'locationUrl': locationUrl,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
