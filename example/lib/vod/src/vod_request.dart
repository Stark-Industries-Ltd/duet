import 'package:json_annotation/json_annotation.dart';

part 'vod_request.g.dart';

@JsonSerializable()
class VodRequest {
  final String title;
  @JsonKey(name: 'fileName')
  final String fileName;
  @JsonKey(name: 'typeReq')
  final String typeReq;
  @JsonKey(name: 'secretKey')
  final String secretKey;

  VodRequest({
    required this.title,
    required this.fileName,
    this.typeReq = 'VIDEO',
    this.secretKey = 'vuihoc-VOD',
  });

  factory VodRequest.fromJson(Map<String, dynamic> json) =>
      _$VodRequestFromJson(json);

  Map<String, dynamic> toJson() => _$VodRequestToJson(this);
}
