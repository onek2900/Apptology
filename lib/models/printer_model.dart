class PrinterModel {
  final int? id; // Auto-incremented ID
  final String name;
  final String category;
  final String printerId; // New field for the printer ID
  final bool isMain;

  PrinterModel({
    this.id,
    required this.name,
    required this.category,
    required this.printerId, // Add printer ID as a required field
    this.isMain = false,
  });

  // Convert PrinterModel to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'printerId': printerId, // Save printer ID in the database
      'isMain': isMain ? 1 : 0, // Store boolean as integer (0 or 1)
    };
  }

  // Convert a Map to PrinterModel
  factory PrinterModel.fromMap(Map<String, dynamic> map) {
    return PrinterModel(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      printerId: map['printerId'], // Retrieve the printer ID from the map
      isMain: map['isMain'] == 1, // Retrieve boolean from integer
    );
  }
}
