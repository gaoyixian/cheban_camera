import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cheban_camera/cheban_camera_method_channel.dart';

void main() {
  MethodChannelChebanCamera platform = MethodChannelChebanCamera();
  const MethodChannel channel = MethodChannel('cheban_camera');

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
