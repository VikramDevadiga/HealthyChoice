enum ScanStatus { safe, caution, danger }

class ProductScan {
  final String name;
  final String description;
  final String imagePath;
  final ScanStatus status;
  final DateTime scanDate;

  ProductScan({
    required this.name,
    required this.description,
    required this.imagePath,
    required this.status,
    required this.scanDate,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'imagePath': imagePath,
    'status': status.name,
    'scanDate': scanDate.toIso8601String(),
  };

  factory ProductScan.fromJson(Map<String, dynamic> json) => ProductScan(
    name: json['name'],
    description: json['description'],
    imagePath: json['imagePath'],
    status: ScanStatus.values.firstWhere((e) => e.name == json['status']),
    scanDate: DateTime.parse(json['scanDate']),
  );
}
