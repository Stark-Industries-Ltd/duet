// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ielts_skill.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IeltsSkill _$IeltsSkillFromJson(Map<String, dynamic> json) => IeltsSkill(
      id: json['id'] as int?,
      isOrder: json['is_order'] as int?,
      title: json['title'] as String?,
      imageIcon: json['image_icon'] as String?,
      imageBackground: json['image_background'] as String?,
      introVideoTablet: json['intro_video_tablet'] as String?,
      introVideoMobile: json['intro_video_mobile'] as String?,
      duration: json['duration'] as int?,
      listMission: (json['list_mission'] as List<dynamic>?)
          ?.map((e) => IeltsMission.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$IeltsSkillToJson(IeltsSkill instance) =>
    <String, dynamic>{
      'id': instance.id,
      'is_order': instance.isOrder,
      'title': instance.title,
      'image_icon': instance.imageIcon,
      'image_background': instance.imageBackground,
      'intro_video_tablet': instance.introVideoTablet,
      'intro_video_mobile': instance.introVideoMobile,
      'duration': instance.duration,
      'list_mission': instance.listMission,
    };
