import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'duet_platform_interface.dart';

typedef OnVideoRecorded = Function(String path);
typedef OnVideoMerged = Function(String path);
typedef OnAudioReceived = Function(String path);
typedef OnTimerVideoReceived = Function(String timer);
typedef OnVideoError = Function(String error);
typedef OnWillEnterForeground = Function(String data);

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
    OnWillEnterForeground? onWillEnterForeground,
    OnVideoError? onAlert,
  }) async {
    methodChannel.setMethodCallHandler((call) {
      log(call.method, name: 'DUET_PLUGIN');
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
        case DuetConst.willEnterForeground:
          return onWillEnterForeground?.call(call.arguments);
        case DuetConst.alert:
          return onAlert?.call(call.arguments);
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

  @override
  Future<bool?> playSound(String url) {
    return methodChannel.invokeMethod<bool>(DuetConst.playSound, url);
  }

  @override
  Future<String?> retryMerge(String url) {
    return methodChannel.invokeMethod<String>(DuetConst.retryMerge, url);
  }

  @override
  Future<String?> reset() {
    return methodChannel.invokeMethod<String>(DuetConst.reset);
  }
}

class DuetConst {
  static const String recordDuet = 'RECORD_DUET';
  static const String pauseDuet = 'PAUSE_DUET';
  static const String resumeDuet = 'RESUME_DUET';
  static const String recordAudio = 'RECORD_AUDIO';
  static const String pauseAudio = 'PAUSE_AUDIO';
  static const String playSound = 'PLAY_SOUND';
  static const String retryMerge = 'RETRY_MERGE';
  static const String reset = 'RESET';

  // Native call
  static const String audioResult = 'AUDIO_RESULT';
  static const String videoRecorded = 'VIDEO_RECORDED';
  static const String videoMerged = 'VIDEO_MERGED';
  static const String videoTimer = 'VIDEO_TIMER';
  static const String videoError = 'VIDEO_ERROR';
  static const String willEnterForeground = 'WILL_ENTER_FOREGROUND';
  static const String alert = 'ALERT';
}
