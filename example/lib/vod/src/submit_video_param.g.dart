// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'submit_video_param.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubmitVideoParam _$SubmitVideoParamFromJson(Map<String, dynamic> json) =>
    SubmitVideoParam(
      videoId: json['video_id'] as String,
      lessonId: json['lesson_id'] as int,
      sectionId: json['section_id'] as int,
      skillId: json['skill_id'] as int?,
      duetVideoId: json['duet_video_id'] as int?,
      fileName: json['file_name'] as String?,
      fileSize: json['file_size'] as int?,
      videoPath: json['video_path'] as String?,
    );

Map<String, dynamic> _$SubmitVideoParamToJson(SubmitVideoParam instance) =>
    <String, dynamic>{
      'video_id': instance.videoId,
      'lesson_id': instance.lessonId,
      'section_id': instance.sectionId,
      'skill_id': instance.skillId,
      'duet_video_id': instance.duetVideoId,
      'file_name': instance.fileName,
      'file_size': instance.fileSize,
      'video_path': instance.videoPath,
    };
