import 'package:duet/duet_method_channel.dart';

import 'duet_platform_interface.dart';

class Duet {
  Future<void> onNativeCall({
    OnVideoRecorded? onVideoRecorded,
    OnAudioReceived? onAudioReceived,
    OnVideoMerged? onVideoMerged,
    OnTimerVideoReceived? onTimerVideoReceived,
    OnVideoError? onVideoError,
    OnWillEnterForeground? onWillEnterForeground,
    OnVideoError? onAlert,
    OnAudioFinish? onAudioFinish,
    OnStopAudioPlayer? onStopAudioPlayer,
  }) async {
    return DuetPlatform.instance.onNativeCall(
      onAudioReceived: onAudioReceived,
      onVideoMerged: onVideoMerged,
      onVideoRecorded: onVideoRecorded,
      onTimerVideoReceived: onTimerVideoReceived,
      onVideoError: onVideoError,
      onWillEnterForeground: onWillEnterForeground,
      onAlert: onAlert,
      onAudioFinish: onAudioFinish,
      onStopAudioPlayer: onStopAudioPlayer,
    );
  }

  Future<String?> recordDuet() => DuetPlatform.instance.recordDuet();

  Future<String?> resumeDuet() => DuetPlatform.instance.resumeDuet();

  Future<String?> pauseDuet() => DuetPlatform.instance.pauseDuet();

  Future<String?> recordAudio() => DuetPlatform.instance.recordAudio();

  Future<String?> pauseAudio() => DuetPlatform.instance.pauseAudio();

  Future<bool?> playSound(String url) => DuetPlatform.instance.playSound(url);

  Future<bool?> playAudioFromUrl(String path) =>
      DuetPlatform.instance.playAudioFromUrl(path);

  Future<String?> stopAudioPlayer() => DuetPlatform.instance.stopAudioPlayer();

  Future<String?> retryMerge(String url) =>
      DuetPlatform.instance.retryMerge(url);

  Future<String?> reset() => DuetPlatform.instance.reset();
}
