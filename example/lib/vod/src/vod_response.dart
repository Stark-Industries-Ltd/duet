import 'package:json_annotation/json_annotation.dart';

part 'vod_response.g.dart';

@JsonSerializable()
class VodResponse {
  final bool? status;
  final VODRes? res;
  final VODMetadata? metadata;

  String get uploadAuth => res?.uploadAuth ?? '';
  String get uploadAddress => res?.uploadAddress ?? '';
  String get videoId => res?.videoId ?? '';

  VodResponse({
    this.status,
    this.res,
    this.metadata,
  });

  factory VodResponse.fromJson(Map<String, dynamic> json) =>
      _$VodResponseFromJson(json);

  Map<String, dynamic> toJson() => _$VodResponseToJson(this);
}

@JsonSerializable()
class VODMetadata {
  @JsonKey(name: 'UserId')
  final String? userId;
  @JsonKey(name: 'Bucket')
  final String? bucket;
  @JsonKey(name: 'Region')
  final String? region;
  @JsonKey(name: 'Endpoint')
  final String? endpoint;

  VODMetadata({
    this.userId,
    this.bucket,
    this.region,
    this.endpoint,
  });

  factory VODMetadata.fromJson(Map<String, dynamic> json) =>
      _$VODMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$VODMetadataToJson(this);
}

@JsonSerializable()
class VODRes {
  @JsonKey(name: 'UploadAddress')
  final String? uploadAddress;
  @JsonKey(name: 'VideoId')
  final String? videoId;
  @JsonKey(name: 'RequestId')
  final String? requestId;
  @JsonKey(name: 'UploadAuth')
  final String? uploadAuth;

  VODRes({
    this.uploadAddress,
    this.videoId,
    this.requestId,
    this.uploadAuth,
  });

  factory VODRes.fromJson(Map<String, dynamic> json) => _$VODResFromJson(json);

  Map<String, dynamic> toJson() => _$VODResToJson(this);
}
