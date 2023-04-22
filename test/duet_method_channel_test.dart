import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:duet/duet_method_channel.dart';

void main() {
  MethodChannelDuet platform = MethodChannelDuet();
  const MethodChannel channel = MethodChannel('duet');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
