// lib/giveaway.dart
class Giveaway {
  final String title;
  final String platforms;
  final String worth;
  final String endDate;
  final String imageUrl;
  final String openGiveawayUrl;
  final String? description; // Optional description for DLC giveaways

  Giveaway({
    required this.title,
    required this.platforms,
    required this.worth,
    required this.endDate,
    required this.imageUrl,
    required this.openGiveawayUrl,
    this.description,
  });

  factory Giveaway.fromJson(Map<String, dynamic> json) {
    return Giveaway(
      title: json['title'] ?? 'No Title', // Default value for title
      platforms: json['platforms'] ?? 'Unknown', // Default value for platforms
      worth: json['worth'] ?? 'N/A', // Default value for worth
      endDate: json['end_date'] ?? "N/A", // Handle null end_date
      imageUrl: json['image_url'] ?? 'default_image.png', // Default image URL if missing
      openGiveawayUrl: json['open_giveaway_url'] ?? '', // Default empty URL
      description: json['description'], // Capture description for DLC
    );
  }
}
