// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ielts_mission.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IeltsMission _$IeltsMissionFromJson(Map<String, dynamic> json) => IeltsMission(
      id: json['id'] as int?,
      name: json['name'] as String?,
      subjectId: json['subject_id'] as int?,
      type: $enumDecodeNullable(_$MissionTypeEnumMap, json['type'],
          unknownValue: MissionType.unknown),
      videoUrl: json['video_url'] as String?,
      subtitleUrl: json['subtitle_url'] as String?,
      description: json['description'] as String?,
      skillId: json['skill_id'] as int?,
      backgroundImage: json['background_image'] as String?,
      totalTimeSkill: json['total_time_skill'] as int?,
      isFirstMissionSkill: json['is_first_mission_skill'] as bool?,
      isIntro: json['is_intro'] as bool? ?? false,
      preDownloadUrl: json['pre_download_url'] as String?,
    );

Map<String, dynamic> _$IeltsMissionToJson(IeltsMission instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'subject_id': instance.subjectId,
      'type': _$MissionTypeEnumMap[instance.type],
      'video_url': instance.videoUrl,
      'subtitle_url': instance.subtitleUrl,
      'description': instance.description,
      'skill_id': instance.skillId,
      'is_intro': instance.isIntro,
      'background_image': instance.backgroundImage,
      'total_time_skill': instance.totalTimeSkill,
      'is_first_mission_skill': instance.isFirstMissionSkill,
      'pre_download_url': instance.preDownloadUrl,
    };

const _$MissionTypeEnumMap = {
  MissionType.videoOnline: 0,
  MissionType.video: 1,
  MissionType.revise: 2,
  MissionType.document: 3,
  MissionType.practice: 4,
  MissionType.unknown: 'unknown',
  MissionType.duet: 6,
};
