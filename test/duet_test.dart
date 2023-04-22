import 'package:flutter_test/flutter_test.dart';
import 'package:duet/duet.dart';
import 'package:duet/duet_platform_interface.dart';
import 'package:duet/duet_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockDuetPlatform 
    with MockPlatformInterfaceMixin
    implements DuetPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final DuetPlatform initialPlatform = DuetPlatform.instance;

  test('$MethodChannelDuet is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelDuet>());
  });

  test('getPlatformVersion', () async {
    Duet duetPlugin = Duet();
    MockDuetPlatform fakePlatform = MockDuetPlatform();
    DuetPlatform.instance = fakePlatform;
  
    expect(await duetPlugin.getPlatformVersion(), '42');
  });
}
