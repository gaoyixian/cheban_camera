import 'package:cheban_camera/camera_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cheban_camera/cheban_camera.dart';
import 'package:cheban_camera/cheban_camera_platform_interface.dart';
import 'package:cheban_camera/cheban_camera_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockChebanCameraPlatform
    with MockPlatformInterfaceMixin
    implements ChebanCameraPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<CameraModel?> pickCamera(
      {int sourceType = CameraTypeAll, int faceType = FaceTypeBack}) {
    // TODO: implement pickCamera
    throw UnimplementedError();
  }
}

void main() {
  final ChebanCameraPlatform initialPlatform = ChebanCameraPlatform.instance;

  test('$MethodChannelChebanCamera is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelChebanCamera>());
  });

  test('getPlatformVersion', () async {
    ChebanCamera chebanCameraPlugin = ChebanCamera();
    MockChebanCameraPlatform fakePlatform = MockChebanCameraPlatform();
    ChebanCameraPlatform.instance = fakePlatform;

    expect(await chebanCameraPlugin.getPlatformVersion(), '42');
  });
}
