class MahalModel {
  final String? id;
  final String mahalName;
  final String price;
  final String location;
  final String? imageBase64;

  MahalModel({
    this.id,
    required this.mahalName,
    required this.price,
    required this.location,
    this.imageBase64,
  });

  factory MahalModel.fromJson(Map<String, dynamic> json) {
    final rawPrice = json['mahal_price'] ?? json['full_day_price'] ?? '0';
    final rawImages = json['mahal_images'];

    return MahalModel(
      id: json['mahal_id']?.toString(),
      mahalName: json['mahal_name'] ?? 'Unknown',
      price: rawPrice?.toString() ?? '0',
      location: json['city'] ?? json['mahal_address'] ?? 'Unknown',
      imageBase64: rawImages is String ? rawImages : null,
    );
  }
}
