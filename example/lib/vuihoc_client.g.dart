// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vuihoc_client.dart';

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

class _VuiHocClient implements VuiHocClient {
  _VuiHocClient(
    this._dio, {
    this.baseUrl,
  }) {
    baseUrl ??= 'https://omo-api.vuihoc.vn/api';
  }

  final Dio _dio;

  String? baseUrl;

  @override
  Future<dynamic> submitVideo(
    param, {
    token,
    appId = 1,
    deviceId = '32777854-FEC9-4554-98E1-8F2F0C8D3EB1',
  }) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    queryParameters.removeWhere((k, v) => v == null);
    final _headers = <String, dynamic>{
      r'Authorization': token,
      r'app-id': appId,
      r'device-id': deviceId,
    };
    _headers.removeWhere((k, v) => v == null);
    final _data = <String, dynamic>{};
    _data.addAll(param?.toJson() ?? <String, dynamic>{});
    final _result = await _dio.fetch(_setStreamType<dynamic>(Options(
      method: 'POST',
      headers: _headers,
      extra: _extra,
    )
        .compose(
          _dio.options,
          '/tutor/video/duet',
          queryParameters: queryParameters,
          data: _data,
        )
        .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = _result.data;
    return value;
  }

  @override
  Future<dynamic> getStudentsByLessonId(lessonId) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    queryParameters.removeWhere((k, v) => v == null);
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch(_setStreamType<dynamic>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
    )
        .compose(
          _dio.options,
          '/tutor-class/get-list-student-by-lesson/${lessonId}',
          queryParameters: queryParameters,
          data: _data,
        )
        .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = _result.data;
    return value;
  }

  @override
  Future<dynamic> getToken({
    birthday,
    uid,
    appId = 1,
    deviceId = '32777854-FEC9-4554-98E1-8F2F0C8D3EB1',
  }) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    queryParameters.removeWhere((k, v) => v == null);
    final _headers = <String, dynamic>{
      r'app-id': appId,
      r'device-id': deviceId,
    };
    _headers.removeWhere((k, v) => v == null);
    final _data = {
      'date_of_birth': birthday,
      'user_id': uid,
    };
    _data.removeWhere((k, v) => v == null);
    final _result = await _dio.fetch(_setStreamType<dynamic>(Options(
      method: 'POST',
      headers: _headers,
      extra: _extra,
    )
        .compose(
          _dio.options,
          '/login-by-date-of-birth',
          queryParameters: queryParameters,
          data: _data,
        )
        .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = _result.data;
    return value;
  }

  @override
  Future<dynamic> getLesson({
    lessonId,
    appId = 1,
    deviceId = '32777854-FEC9-4554-98E1-8F2F0C8D3EB1',
    token,
  }) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    queryParameters.removeWhere((k, v) => v == null);
    final _headers = <String, dynamic>{
      r'app-id': appId,
      r'device-id': deviceId,
      r'Authorization': token,
    };
    _headers.removeWhere((k, v) => v == null);
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch(_setStreamType<dynamic>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
    )
        .compose(
          _dio.options,
          '/tutor-lesson/${lessonId}',
          queryParameters: queryParameters,
          data: _data,
        )
        .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = _result.data;
    return value;
  }

  RequestOptions _setStreamType<T>(RequestOptions requestOptions) {
    if (T != dynamic &&
        !(requestOptions.responseType == ResponseType.bytes ||
            requestOptions.responseType == ResponseType.stream)) {
      if (T == String) {
        requestOptions.responseType = ResponseType.plain;
      } else {
        requestOptions.responseType = ResponseType.json;
      }
    }
    return requestOptions;
  }
}
