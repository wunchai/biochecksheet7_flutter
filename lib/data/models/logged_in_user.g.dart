// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logged_in_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoggedInUser _$LoggedInUserFromJson(Map<String, dynamic> json) => LoggedInUser(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      userCode: json['userCode'] as String,
      password: json['password'] as String,
      position: json['position'] as String?,
      status: (json['status'] as num?)?.toInt(),
    );

Map<String, dynamic> _$LoggedInUserToJson(LoggedInUser instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'displayName': instance.displayName,
      'userCode': instance.userCode,
      'password': instance.password,
      'position': instance.position,
      'status': instance.status,
    };
