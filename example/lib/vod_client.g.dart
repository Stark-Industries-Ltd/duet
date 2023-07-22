// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vod_client.dart';

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

class _VODClient implements VODClient {
  _VODClient(
    this._dio, {
    this.baseUrl,
  }) {
    baseUrl ??= 'https://aj5w7cw442.execute-api.ap-southeast-1.amazonaws.com';
  }

  final Dio _dio;

  String? baseUrl;

  @override
  Future<VodResponse> getSlot(request) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(request.toJson());
    final _result = await _dio
        .fetch<Map<String, dynamic>>(_setStreamType<VodResponse>(Options(
      method: 'POST',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              '/',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = VodResponse.fromJson(_result.data!);
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
