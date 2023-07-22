// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vod_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VodRequest _$VodRequestFromJson(Map<String, dynamic> json) => VodRequest(
      title: json['title'] as String,
      fileName: json['fileName'] as String,
      typeReq: json['typeReq'] as String? ?? 'VIDEO',
      secretKey: json['secretKey'] as String? ?? 'vuihoc-VOD',
    );

Map<String, dynamic> _$VodRequestToJson(VodRequest instance) =>
    <String, dynamic>{
      'title': instance.title,
      'fileName': instance.fileName,
      'typeReq': instance.typeReq,
      'secretKey': instance.secretKey,
    };
