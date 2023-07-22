import 'package:json_annotation/json_annotation.dart';

import 'ielts_skill.dart';
import 'ielts_student.dart';

part 'ielts_lesson.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class IeltsLesson {
  final int? lessonId;
  final String? lessonName;
  final List<IeltsStudent>? students;

  ///Chi tiết buổi học'
  final int? sectionId;
  final int? totalTime;
  final String? titleLesson;
  final String? descLesson;
  final String? audioWelcome;
  final String? imageBackgroundMobile;
  final String? imageBackgroundTablet;
  final List<IeltsSkill>? skills;

  IeltsLesson({
    this.lessonId,
    this.lessonName,
    this.students,
    this.sectionId,
    this.totalTime,
    this.titleLesson,
    this.descLesson,
    this.audioWelcome,
    this.imageBackgroundMobile,
    this.imageBackgroundTablet,
    this.skills,
  });

  factory IeltsLesson.fromJson(Map<String, dynamic> json) =>
      _$IeltsLessonFromJson(json);

  Map<String, dynamic> toJson() => _$IeltsLessonToJson(this);
}
