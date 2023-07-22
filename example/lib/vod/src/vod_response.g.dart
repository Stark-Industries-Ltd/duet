// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vod_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VodResponse _$VodResponseFromJson(Map<String, dynamic> json) => VodResponse(
      status: json['status'] as bool?,
      res: json['res'] == null
          ? null
          : VODRes.fromJson(json['res'] as Map<String, dynamic>),
      metadata: json['metadata'] == null
          ? null
          : VODMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$VodResponseToJson(VodResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'res': instance.res,
      'metadata': instance.metadata,
    };

VODMetadata _$VODMetadataFromJson(Map<String, dynamic> json) => VODMetadata(
      userId: json['UserId'] as String?,
      bucket: json['Bucket'] as String?,
      region: json['Region'] as String?,
      endpoint: json['Endpoint'] as String?,
    );

Map<String, dynamic> _$VODMetadataToJson(VODMetadata instance) =>
    <String, dynamic>{
      'UserId': instance.userId,
      'Bucket': instance.bucket,
      'Region': instance.region,
      'Endpoint': instance.endpoint,
    };

VODRes _$VODResFromJson(Map<String, dynamic> json) => VODRes(
      uploadAddress: json['UploadAddress'] as String?,
      videoId: json['VideoId'] as String?,
      requestId: json['RequestId'] as String?,
      uploadAuth: json['UploadAuth'] as String?,
    );

Map<String, dynamic> _$VODResToJson(VODRes instance) => <String, dynamic>{
      'UploadAddress': instance.uploadAddress,
      'VideoId': instance.videoId,
      'RequestId': instance.requestId,
      'UploadAuth': instance.uploadAuth,
    };
