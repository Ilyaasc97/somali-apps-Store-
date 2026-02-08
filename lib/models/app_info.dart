class AppInfo {
  final String name;
  final String description;
  final String iconUrl;
  final String downloadUrl;
  final String size;
  final List<String> screenshots;
  final String version;
  final String developer;
  final double rating;
  final String packageName;

  AppInfo({
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.downloadUrl,
    required this.size,
    required this.screenshots,
    required this.version,
    required this.developer,
    required this.rating,
    required this.packageName,
  });

  // تحويل JSON القادم من الإنترنت إلى كائن (Object)
  factory AppInfo.fromJson(Map<String, dynamic> json) {
    return AppInfo(
      name: json['name'] ?? 'بدون اسم',
      description: json['description'] ?? 'لا يوجد وصف',
      iconUrl: json['iconUrl'] ?? '',
      downloadUrl: json['downloadUrl'] ?? '',
      size: json['size'] ?? 'Unknown',
      screenshots: List<String>.from(json['screenshots'] ?? []),
      version: json['version'] ?? '1.0.0',
      developer: json['developer'] ?? 'Unknown',
      rating: (json['rating'] ?? 4.5).toDouble(),
      packageName: json['packageName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'iconUrl': iconUrl,
      'downloadUrl': downloadUrl,
      'size': size,
      'screenshots': screenshots,
      'version': version,
      'developer': developer,
      'rating': rating,
      'packageName': packageName,
      'searchKeywords': _generateSearchKeywords(),
    };
  }

  List<String> _generateSearchKeywords() {
    List<String> keywords = [];
    String lowerName = name.toLowerCase();
    for (int i = 1; i <= lowerName.length; i++) {
      keywords.add(lowerName.substring(0, i));
    }
    return keywords;
  }
}
