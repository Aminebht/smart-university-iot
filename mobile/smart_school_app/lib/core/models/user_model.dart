import 'package:supabase_flutter/supabase_flutter.dart';

class UserModel {
  final String id;
  final String? email;
  final String? name;
  final String? role;
  
  UserModel({
    required this.id,
    this.email,
    this.name,
    this.role,
  });
  
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      role: json['role'],
    );
  }
  
  // Add this method to support creation from Supabase User
  factory UserModel.fromSupabase(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      // Get name from user metadata if available
      name: user.userMetadata?['name'] as String? ?? 
            user.userMetadata?['full_name'] as String? ??
            user.email?.split('@')[0],
      // Get role from app_metadata or default to 'teacher'
      role: user.appMetadata['role'] as String? ?? 'teacher',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
    };
  }
  
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
    );
  }
}