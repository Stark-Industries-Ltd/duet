
import 'duet_platform_interface.dart';

class Duet {
  Future<String?> getPlatformVersion() {
    return DuetPlatform.instance.getPlatformVersion();
  }
}
