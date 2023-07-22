import 'package:json_annotation/json_annotation.dart';

import 'ielts_mission.dart';

part 'ielts_skill.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class IeltsSkill {
  ///LMSID
  final int? id;

  ///Bắt buộc làm tuần tự hay không
  final int? isOrder;
  final String? title;
  final String? imageIcon;
  final String? imageBackground;
  final String? introVideoTablet;
  final String? introVideoMobile;
  final int? duration;
  final List<IeltsMission>? listMission;

  IeltsSkill({
    this.id,
    this.isOrder,
    this.title,
    this.imageIcon,
    this.imageBackground,
    this.introVideoTablet,
    this.introVideoMobile,
    this.duration,
    this.listMission,
  });

  factory IeltsSkill.fromJson(Map<String, dynamic> json) =>
      _$IeltsSkillFromJson(json);

  Map<String, dynamic> toJson() => _$IeltsSkillToJson(this);
}
