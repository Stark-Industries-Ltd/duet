import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'vod/src/submit_video_param.dart';

part 'vuihoc_client.g.dart';

@RestApi(baseUrl: 'https://omo-api.vuihoc.vn/api')
abstract class VuiHocClient {
  factory VuiHocClient(Dio dio, {String baseUrl}) = _VuiHocClient;

  @POST('/tutor/video/duet')
  Future<dynamic> submitVideo(
    @Body() SubmitVideoParam? param, {
    @Header('Authorization') String? token,
    @Header('app-id') int appId = 1,
    @Header('device-id')
        String deviceId = '32777854-FEC9-4554-98E1-8F2F0C8D3EB1',
  });

  @GET('/tutor-class/get-list-student-by-lesson/{lesson_id}')
  Future<dynamic> getStudentsByLessonId(
    @Path('lesson_id') String? lessonId,
  );

  @POST('/login-by-date-of-birth')
  Future<dynamic> getToken({
    @Field('date_of_birth') String? birthday,
    @Field('user_id') int? uid,
    @Header('app-id') int appId = 1,
    @Header('device-id')
        String deviceId = '32777854-FEC9-4554-98E1-8F2F0C8D3EB1',
  });

  @GET('/tutor-lesson/{lesson_id}')
  Future<dynamic> getLesson({
    @Path('lesson_id') String? lessonId,
    @Header('app-id') int appId = 1,
    @Header('device-id')
        String deviceId = '32777854-FEC9-4554-98E1-8F2F0C8D3EB1',
    @Header('Authorization') String? token,
  });
}
