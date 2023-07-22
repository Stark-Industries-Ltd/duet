import 'package:json_annotation/json_annotation.dart';

part 'submit_video_param.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class SubmitVideoParam {
  final String videoId;
  final int lessonId;
  final int sectionId;
  final int? skillId;
  final int? duetVideoId;
  final String? fileName;
  final int? fileSize;
  final String? videoPath;

  SubmitVideoParam({
    required this.videoId,
    required this.lessonId,
    required this.sectionId,
    this.skillId,
    this.duetVideoId,
    this.fileName,
    this.fileSize,
    this.videoPath,
  });

  factory SubmitVideoParam.fromJson(Map<String, dynamic> json) =>
      _$SubmitVideoParamFromJson(json);

  Map<String, dynamic> toJson() => _$SubmitVideoParamToJson(this);
}
