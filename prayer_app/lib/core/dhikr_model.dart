class DhikrItem {
  final String id;
  final String category; // 'morning' | 'evening'
  final int order;
  final int count;
  final String title;
  final String arabic;
  final String translationFa;
  final String translationKu;
  final String virtue;
  final String source;

  const DhikrItem({
    required this.id,
    required this.category,
    required this.order,
    required this.count,
    required this.title,
    required this.arabic,
    required this.translationFa,
    required this.translationKu,
    required this.virtue,
    required this.source,
  });

  factory DhikrItem.fromJson(Map<String, dynamic> json) {
    return DhikrItem(
      id: json['id'] as String? ?? '',
      category: json['category'] as String? ?? '',
      order: json['order'] as int? ?? 0,
      count: json['count'] as int? ?? 1,
      title: json['title'] as String? ?? '',
      arabic: json['arabic'] as String? ?? '',
      translationFa: json['translation_fa'] as String? ?? '',
      translationKu: json['translation_ku'] as String? ?? '',
      virtue: json['virtue'] as String? ?? '',
      source: json['source'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'order': order,
        'count': count,
        'title': title,
        'arabic': arabic,
        'translation_fa': translationFa,
        'translation_ku': translationKu,
        'virtue': virtue,
        'source': source,
      };
}
