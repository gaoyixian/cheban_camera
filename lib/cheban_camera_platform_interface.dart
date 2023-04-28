import 'package:cheban_camera/camera_model.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'cheban_camera_method_channel.dart';

abstract class ChebanCameraPlatform extends PlatformInterface {
  /// Constructs a ChebanCameraPlatform.
  ChebanCameraPlatform() : super(token: _token);

  static final Object _token = Object();

  static ChebanCameraPlatform _instance = MethodChannelChebanCamera();

  /// The default instance of [ChebanCameraPlatform] to use.
  ///
  /// Defaults to [MethodChannelChebanCamera].
  static ChebanCameraPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ChebanCameraPlatform] when
  /// they register themselves.
  static set instance(ChebanCameraPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<CameraModel?> pickCamera(
      {int sourceType = CameraTypeAll, int faceType = FaceTypeBack, int animated = 1}) {
    throw UnimplementedError('pickCamera() has not been implemented.');
  }

  Future<void> destory() {
    throw UnimplementedError('destory() has not been implemented.');
  }
}
