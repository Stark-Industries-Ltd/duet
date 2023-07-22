import 'package:dio/dio.dart';
import 'package:duet_example/vod/index.dart';
import 'package:retrofit/retrofit.dart';

part 'vod_client.g.dart';

@RestApi(baseUrl: 'https://aj5w7cw442.execute-api.ap-southeast-1.amazonaws.com')
abstract class VODClient {
  factory VODClient(Dio dio, {String baseUrl}) = _VODClient;

  @POST('/')
  Future<VodResponse> getSlot(@Body() VodRequest request);
}
