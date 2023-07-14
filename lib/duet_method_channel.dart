import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'duet_platform_interface.dart';

typedef OnVideoRecorded = Function(String path);
typedef OnVideoMerged = Function(String path);
typedef OnAudioReceived = Function(String path);
typedef OnTimerVideoReceived = Function(String timer);
typedef OnVideoError = Function(String error);

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
    OnTimerVideoReceived? onTimerVideoReceived,
    OnVideoError? onVideoError,
  }) async {
    methodChannel.setMethodCallHandler((call) {
      switch (call.method) {
        case DuetConst.videoRecorded:
          return onVideoRecorded?.call(call.arguments);
        case DuetConst.audioResult:
          return onAudioReceived?.call(call.arguments);
        case DuetConst.videoMerged:
          return onVideoMerged?.call(call.arguments);
        case DuetConst.videoTimer:
          return onTimerVideoReceived?.call(call.arguments);
        case DuetConst.videoError:
          return onVideoError?.call(call.arguments);
        default:
          return Future(() => null);
      }
    });
  }

  @override
  Future<String?> recordDuet() {
    final result = methodChannel.invokeMethod<String>(DuetConst.recordDuet);
    return result;
  }

  @override
  Future<String?> pauseDuet() {
    final result = methodChannel.invokeMethod<String>(DuetConst.pauseDuet);
    return result;
  }

  @override
  Future<String?> resumeDuet() {
    final result = methodChannel.invokeMethod<String>(DuetConst.resumeDuet);
    return result;
  }

  Future<String?> resetDuet() {
    final result = methodChannel.invokeMethod<String>(DuetConst.resetDuet);
    return result;
  }

  @override
  Future<String?> pauseAudio() {
    final result = methodChannel.invokeMethod<String>(DuetConst.pauseAudio);
    return result;
  }

  @override
  Future<String?> recordAudio() {
    final result = methodChannel.invokeMethod<String>(DuetConst.recordAudio);
    return result;
  }

  Future<String?> startCamera() {
    final result = methodChannel.invokeMethod<String>(DuetConst.startCamera);
    return result;
  }

  Future<String?> stopCamera() {
    final result = methodChannel.invokeMethod<String>(DuetConst.stopCamera);
    return result;
  }

  Future<String?> resetCamera() {
    final result = methodChannel.invokeMethod<String>(DuetConst.resetCamera);
    return result;
  }

  @override
  Future<bool?> playSound(String url) {
    return methodChannel.invokeMethod<bool>(DuetConst.playSound, url);
  }

  @override
  Future<bool?> saveVideoToAlbum(String path) {
    return methodChannel.invokeMethod<bool>(DuetConst.saveVideoToAlbum, path);
  }
}

class DuetConst {
  static const String recordDuet = 'RECORD_DUET';
  static const String pauseDuet = 'PAUSE_DUET';
  static const String resumeDuet = 'RESUME_DUET';
  static const String resetDuet = 'RESET_DUET';
  static const String recordAudio = 'RECORD_AUDIO';
  static const String pauseAudio = 'PAUSE_AUDIO';
  static const String startCamera = 'START_CAMERA';
  static const String stopCamera = 'STOP_CAMERA';
  static const String resetCamera = 'RESET_CAMERA';
  static const String playSound = 'PLAY_SOUND';
  static const String saveVideoToAlbum = 'SAVE_VIDEO_TO_ALBUM';

  // Native call
  static const String audioResult = 'AUDIO_RESULT';
  static const String videoRecorded = 'VIDEO_RECORDED';
  static const String videoMerged = 'VIDEO_MERGED';
  static const String videoTimer = 'VIDEO_TIMER';
  static const String videoError = 'VIDEO_ERROR';
}
