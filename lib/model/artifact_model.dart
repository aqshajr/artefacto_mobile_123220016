class Artifact {
  final int artifactID;
  final int templeID;
  final String? imageUrl;
  final String title;
  final String description;
  final String? detailPeriod;
  final String? detailMaterial;
  final String? detailSize;
  final String? detailStyle;
  final String? funfactTitle;
  final String? funfactDescription;
  final String? locationUrl;
  final String templeTitle;
  final bool isBookmarked;
  final bool isRead;
  final double? latitude;
  final double? longitude;

  Artifact({
    required this.artifactID,
    required this.templeID,
    this.imageUrl,
    required this.title,
    required this.description,
    this.detailPeriod,
    this.detailMaterial,
    this.detailSize,
    this.detailStyle,
    this.funfactTitle,
    this.funfactDescription,
    this.locationUrl,
    required this.templeTitle,
    required this.isBookmarked,
    required this.isRead,
    this.latitude,
    this.longitude,
  });

  factory Artifact.fromJson(Map<String, dynamic> json) {
    double? lat, lng;
    final url = json['locationUrl'] as String?;
    if (url != null) {
      final regex = RegExp(r'@(-?\d+\.\d+),(-?\d+\.\d+)');
      final match = regex.firstMatch(url);
      if (match != null) {
        lat = double.tryParse(match.group(1)!);
        lng = double.tryParse(match.group(2)!);
      }
    }

    return Artifact(
      artifactID: json['artifactID'] as int,
      templeID: json['templeID'] as int,
      imageUrl: json['imageUrl'] as String?,
      title: json['title'] as String,
      description: json['description'] as String,
      detailPeriod: json['detailPeriod'] as String?,
      detailMaterial: json['detailMaterial'] as String?,
      detailSize: json['detailSize'] as String?,
      detailStyle: json['detailStyle'] as String?,
      funfactTitle: json['funfactTitle'] as String?,
      funfactDescription: json['funfactDescription'] as String?,
      locationUrl: url,
      templeTitle: json['Temple']?['title'] ?? '',
      isBookmarked: json['isBookmarked'] == true,
      isRead: json['isRead'] == true,
      latitude: lat,
      longitude: lng,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'artifactID': artifactID,
      'templeID': templeID,
      'imageUrl': imageUrl,
      'title': title,
      'description': description,
      'detailPeriod': detailPeriod,
      'detailMaterial': detailMaterial,
      'detailSize': detailSize,
      'detailStyle': detailStyle,
      'funfactTitle': funfactTitle,
      'funfactDescription': funfactDescription,
      'locationUrl': locationUrl,
    };
  }
}

class ArtifactRequest {
  final int templeID;
  final String title;
  final String description;
  final String? detailPeriod;
  final String? detailMaterial;
  final String? detailSize;
  final String? detailStyle;
  final String? funfactTitle;
  final String? funfactDescription;
  final String? locationUrl;

  ArtifactRequest({
    required this.templeID,
    required this.title,
    required this.description,
    this.detailPeriod,
    this.detailMaterial,
    this.detailSize,
    this.detailStyle,
    this.funfactTitle,
    this.funfactDescription,
    this.locationUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'templeID': templeID,
      'title': title,
      'description': description,
      'detailPeriod': detailPeriod,
      'detailMaterial': detailMaterial,
      'detailSize': detailSize,
      'detailStyle': detailStyle,
      'funfactTitle': funfactTitle,
      'funfactDescription': funfactDescription,
      'locationUrl': locationUrl,
    };
  }
}
