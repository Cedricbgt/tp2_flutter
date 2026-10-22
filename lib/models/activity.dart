import 'package:cloud_firestore/cloud_firestore.dart';

/// Activité stockée dans la collection Firestore `activities`.
class Activity {
  const Activity({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.category,
    required this.location,
    required this.price,
    required this.maxPeople,
  });

  final String id;
  final String title;
  final String imageUrl;
  final String category;
  final String location;
  final double price;
  final int maxPeople;

  /// Prix affiché : « 25 € » ou « 12,50 € ».
  String get formattedPrice {
    final value = price == price.roundToDouble()
        ? price.toStringAsFixed(0)
        : price.toStringAsFixed(2).replaceAll('.', ',');
    return '$value €';
  }

  factory Activity.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Activity(
      id: doc.id,
      title: data['title'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      category: data['category'] as String? ?? '',
      location: data['location'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      maxPeople: (data['maxPeople'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'title': title,
    'imageUrl': imageUrl,
    'category': category,
    'location': location,
    'price': price,
    'maxPeople': maxPeople,
  };
}
