import 'package:json_annotation/json_annotation.dart';

part 'vod_upload_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class VODUploadModel {
  final int lessonId;
  final int sectionId;
  final String videoId;
  final String fileName;
  final String uploadAuth;
  final String uploadAddress;
  final String pathVideo;
  final String? pathUpload;

  VODUploadModel({
    required this.lessonId,
    required this.sectionId,
    required this.videoId,
    required this.fileName,
    required this.uploadAuth,
    required this.uploadAddress,
    required this.pathVideo,
    this.pathUpload,
  });

  factory VODUploadModel.fromJson(Map<String, dynamic> json) =>
      _$VODUploadModelFromJson(json);

  Map<String, dynamic> toJson() => _$VODUploadModelToJson(this);
}
