import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'duet_platform_interface.dart';

/// An implementation of [DuetPlatform] that uses method channels.
class MethodChannelDuet extends DuetPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('duet');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
