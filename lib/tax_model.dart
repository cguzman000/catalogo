class Tax {
  final String id;
  final String name;
  final double percentage;

  Tax({required this.id, required this.name, required this.percentage});

  factory Tax.fromJson(Map<String, dynamic> json) {
    return Tax(
      id: json['id'] as String,
      name: json['name'] as String,
      percentage: (json['percentage'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'percentage': percentage};
  }

  Tax copyWith({String? id, String? name, double? percentage}) {
    return Tax(
      id: id ?? this.id,
      name: name ?? this.name,
      percentage: percentage ?? this.percentage,
    );
  }
}
