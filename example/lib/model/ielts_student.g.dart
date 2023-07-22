// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ielts_student.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IeltsStudent _$IeltsStudentFromJson(Map<String, dynamic> json) => IeltsStudent(
      coreUserId: json['core_user_id'] as int?,
      fullName: json['full_name'] as String?,
      avatar: json['avatar'] as String?,
      birthday: json['birthday'] as String?,
      id: json['id'] as int?,
      token: json['token'] as String?,
    );

Map<String, dynamic> _$IeltsStudentToJson(IeltsStudent instance) =>
    <String, dynamic>{
      'core_user_id': instance.coreUserId,
      'full_name': instance.fullName,
      'avatar': instance.avatar,
      'birthday': instance.birthday,
      'id': instance.id,
      'token': instance.token,
    };
