class StudentModel {
  final int id;
  final String name;
  final String? email;

  StudentModel({
    required this.id,
    required this.name,
    this.email,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      email: json['email']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }
}