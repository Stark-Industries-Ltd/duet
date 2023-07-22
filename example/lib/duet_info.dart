import 'package:json_annotation/json_annotation.dart';

part 'duet_info.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class DuetInfo {
  final String? userName;
  final int? userId;
  final int? lessonId;
  final int? sectionId;
  final int? skillId;
  final int? duetVideoId;
  final String? videoDuet;
  final String? token;
  String? userVideo;

  DuetInfo({
    this.userName,
    this.userId,
    this.lessonId,
    this.sectionId,
    this.skillId,
    this.duetVideoId,
    this.videoDuet,
    this.token,
    this.userVideo,
  });

  factory DuetInfo.fromJson(Map<String, dynamic> json) =>
      _$DuetInfoFromJson(json);

  Map<String, dynamic> toJson() => _$DuetInfoToJson(this);
}
