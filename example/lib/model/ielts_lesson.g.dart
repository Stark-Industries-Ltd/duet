// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ielts_lesson.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IeltsLesson _$IeltsLessonFromJson(Map<String, dynamic> json) => IeltsLesson(
      lessonId: json['lesson_id'] as int?,
      lessonName: json['lesson_name'] as String?,
      students: (json['students'] as List<dynamic>?)
          ?.map((e) => IeltsStudent.fromJson(e as Map<String, dynamic>))
          .toList(),
      sectionId: json['section_id'] as int?,
      totalTime: json['total_time'] as int?,
      titleLesson: json['title_lesson'] as String?,
      descLesson: json['desc_lesson'] as String?,
      audioWelcome: json['audio_welcome'] as String?,
      imageBackgroundMobile: json['image_background_mobile'] as String?,
      imageBackgroundTablet: json['image_background_tablet'] as String?,
      skills: (json['skills'] as List<dynamic>?)
          ?.map((e) => IeltsSkill.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$IeltsLessonToJson(IeltsLesson instance) =>
    <String, dynamic>{
      'lesson_id': instance.lessonId,
      'lesson_name': instance.lessonName,
      'students': instance.students,
      'section_id': instance.sectionId,
      'total_time': instance.totalTime,
      'title_lesson': instance.titleLesson,
      'desc_lesson': instance.descLesson,
      'audio_welcome': instance.audioWelcome,
      'image_background_mobile': instance.imageBackgroundMobile,
      'image_background_tablet': instance.imageBackgroundTablet,
      'skills': instance.skills,
    };
