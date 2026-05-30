import 'package:flutter/material.dart';

class StudentModel {
  final int studentId;
  final String name;
  final String email;
  final String? rfidUid;
  
  StudentModel({
    required this.studentId,
    required this.name,
    required this.email,
    this.rfidUid,
  });
  
  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      studentId: json['student_id'],
      name: json['name'],
      email: json['email'],
      rfidUid: json['rfid_uid'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'name': name,
      'email': email,
      'rfid_uid': rfidUid,
    };
  }
}