/// A product category (GET /categories).
class Category {
  final String id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? '',
      );
}
