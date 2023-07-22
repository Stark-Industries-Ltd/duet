// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vod_upload_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VODUploadModel _$VODUploadModelFromJson(Map<String, dynamic> json) =>
    VODUploadModel(
      lessonId: json['lesson_id'] as int,
      sectionId: json['section_id'] as int,
      videoId: json['video_id'] as String,
      fileName: json['file_name'] as String,
      uploadAuth: json['upload_auth'] as String,
      uploadAddress: json['upload_address'] as String,
      pathVideo: json['path_video'] as String,
      pathUpload: json['path_upload'] as String?,
    );

Map<String, dynamic> _$VODUploadModelToJson(VODUploadModel instance) =>
    <String, dynamic>{
      'lesson_id': instance.lessonId,
      'section_id': instance.sectionId,
      'video_id': instance.videoId,
      'file_name': instance.fileName,
      'upload_auth': instance.uploadAuth,
      'upload_address': instance.uploadAddress,
      'path_video': instance.pathVideo,
      'path_upload': instance.pathUpload,
    };
