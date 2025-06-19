// lib/data/models/logged_in_user.dart
import 'package:json_annotation/json_annotation.dart';

part 'logged_in_user.g.dart';

@JsonSerializable()
class LoggedInUser {
  final String userId;
  final String displayName;
  final String userCode;
  final String password;
  final String? position; // <<< เพิ่ม field นี้
  final int? status;     // <<< เพิ่ม field นี้

  // Added 'const' to the constructor
  const LoggedInUser({ // <<< Added 'const' here
    required this.userId,
    required this.displayName,
    required this.userCode,
    required this.password,
    this.position, // <<< เพิ่มใน constructor
    this.status,   // <<< เพิ่มใน constructor
  });

  factory LoggedInUser.fromJson(Map<String, dynamic> json) => _$LoggedInUserFromJson(json);
  Map<String, dynamic> toJson() => _$LoggedInUserToJson(this);
}