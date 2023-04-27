import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'duet_platform_interface.dart';

typedef OnVideoRecorded = Function(String path);
typedef OnVideoMerged = Function(String path);
typedef OnAudioReceived = Function(String path);

/// An implementation of [DuetPlatform] that uses method channels.
class MethodChannelDuet extends DuetPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('duet');

  @override
  Future<void> onNativeCall({
    OnVideoRecorded? onVideoRecorded,
    OnAudioReceived? onAudioReceived,
    OnVideoMerged? onVideoMerged,
  }) async {
    methodChannel.setMethodCallHandler((call) {
      switch (call.method) {
        case DuetConst.videoRecorded:
          return onVideoRecorded?.call(call.arguments);
        case DuetConst.audioResult:
          return onAudioReceived?.call(call.arguments);
        case DuetConst.videoMerged:
          return onVideoMerged?.call(call.arguments);
        default:
          return Future(() => null);
      }
    });
  }

  @override
  Future<String?> resetDuet() {
    final result = methodChannel.invokeMethod<String>(DuetConst.reset);
    return result;
  }

  @override
  Future<String?> recordDuet() {
    final result = methodChannel.invokeMethod<String>(DuetConst.record);
    return result;
  }
}

class DuetConst {
  static const String record = 'RECORD';
  static const String reset = 'RESET';

  // Native call

  static const String audioResult = 'AUDIO_RESULT';
  static const String videoRecorded = 'VIDEO_RECORDED';
  static const String videoMerged = 'VIDEO_MERGED';
}
