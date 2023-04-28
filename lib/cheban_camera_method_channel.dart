import 'package:cheban_camera/camera_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'cheban_camera_platform_interface.dart';

/// An implementation of [ChebanCameraPlatform] that uses method channels.
class MethodChannelChebanCamera extends ChebanCameraPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('cheban_camera');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<CameraModel?> pickCamera(
      {int sourceType = CameraTypeAll, int faceType = FaceTypeBack, int animated = 1}) async {
    Map? _map = await methodChannel.invokeMethod('takePhotoAndVideo',
        {"source_type": sourceType, "face_type": faceType, 'animated': animated});
    if (_map != null) {
      Map<String, dynamic> _muMap = {};
      for (var key in _map.keys) {
        _muMap[key.toString()] = _map[key];
      }
      return CameraModel.fromJson(_muMap);
    }
    return null;
  }

  @override
  Future<void> destory() async {
    methodChannel.invokeMethod('destory');
  }
}
