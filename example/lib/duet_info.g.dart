// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'duet_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DuetInfo _$DuetInfoFromJson(Map<String, dynamic> json) => DuetInfo(
      userName: json['user_name'] as String?,
      userId: json['user_id'] as int?,
      lessonId: json['lesson_id'] as int?,
      sectionId: json['section_id'] as int?,
      skillId: json['skill_id'] as int?,
      duetVideoId: json['duet_video_id'] as int?,
      videoDuet: json['video_duet'] as String?,
      token: json['token'] as String?,
      userVideo: json['user_video'] as String?,
    );

Map<String, dynamic> _$DuetInfoToJson(DuetInfo instance) => <String, dynamic>{
      'user_name': instance.userName,
      'user_id': instance.userId,
      'lesson_id': instance.lessonId,
      'section_id': instance.sectionId,
      'skill_id': instance.skillId,
      'duet_video_id': instance.duetVideoId,
      'video_duet': instance.videoDuet,
      'token': instance.token,
      'user_video': instance.userVideo,
    };
