class PrinterModel {
  final int? id;
  final String name;
  final String category;

  PrinterModel({this.id, required this.name, required this.category});

  // Convert PrinterModel to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
    };
  }

  // Convert a Map to PrinterModel
  factory PrinterModel.fromMap(Map<String, dynamic> map) {
    return PrinterModel(
      id: map['id'],
      name: map['name'],
      category: map['category'],
    );
  }
}
