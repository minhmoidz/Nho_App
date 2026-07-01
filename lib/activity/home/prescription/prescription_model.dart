class Prescription {
  final String id;
  final String name;
  final String imagePath;
  final String timeText;
  final String note;
  final DateTime createdAt;

  Prescription({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.timeText,
    required this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'imagePath': imagePath,
    'timeText': timeText,
    'note': note,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Prescription.fromJson(Map<String, dynamic> json) => Prescription(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    imagePath: json['imagePath'] ?? '',
    timeText: json['timeText'] ?? '',
    note: json['note'] ?? '',
    createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
  );
}
