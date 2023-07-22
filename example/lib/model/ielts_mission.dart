import 'package:json_annotation/json_annotation.dart';

part 'ielts_mission.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class IeltsMission {
  final int? id;
  final String? name;
  final int? subjectId;
  @JsonKey(unknownEnumValue: MissionType.unknown)
  final MissionType? type;

  ///DUET
  final String? videoUrl;
  final String? subtitleUrl;
  final String? description;
  int? skillId;
  bool isIntro;
  String? backgroundImage;
  int? totalTimeSkill;
  bool? isFirstMissionSkill;
  String? preDownloadUrl;

  IeltsMission({
    this.id,
    this.name,
    this.subjectId,
    this.type,
    this.videoUrl,
    this.subtitleUrl,
    this.description,
    this.skillId,
    this.backgroundImage,
    this.totalTimeSkill,
    this.isFirstMissionSkill,
    this.isIntro = false,
    this.preDownloadUrl,
  });

  bool get isDuet => type == MissionType.duet;

  factory IeltsMission.fromJson(Map<String, dynamic> json) =>
      _$IeltsMissionFromJson(json);

  Map<String, dynamic> toJson() => _$IeltsMissionToJson(this);
}

enum MissionType {
  @JsonValue(0)
  videoOnline,
  @JsonValue(1)
  video,
  @JsonValue(2)
  revise,
  @JsonValue(3)
  document,
  @JsonValue(4)
  practice,
  unknown,
  @JsonValue(6)
  duet,
}
