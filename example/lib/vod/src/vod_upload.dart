import 'package:flutter/services.dart';

class VODUpload {
  final methodChannel = const MethodChannel('com.vod.client');

  Future<void> upload(Map args) async {
    return methodChannel.invokeMethod('UPLOAD', args);
  }

  Future<void> onNativeCall({
    Function(String path)? onSuccess,
    Function(String arguments)? onError,
    Function(int? count, int? total)? onProgress,
  }) async {
    methodChannel.setMethodCallHandler((call) {
      switch (call.method) {
        case 'SUCCESS':
          return onSuccess?.call(call.arguments);
        case 'ERROR':
          return onError?.call(call.arguments);
        case 'PROGRESS':
          final data = call.arguments.toString().split("|");
          return onProgress?.call(
            int.tryParse(data.first),
            int.tryParse(data.last),
          );
        default:
          return Future(() => null);
      }
    });
  }
}
