import 'package:cheban_camera/camera_model.dart';

import 'cheban_camera_platform_interface.dart';

class ChebanCamera {
  Future<String?> getPlatformVersion() {
    return ChebanCameraPlatform.instance.getPlatformVersion();
  }

  Future<CameraModel?> pickCamera(
      {int sourceType = CameraTypeAll, int faceType = FaceTypeBack, int animated = 1}) {
    return ChebanCameraPlatform.instance
        .pickCamera(sourceType: sourceType, faceType: faceType, animated: animated);
  }

  Future<void> destory() {
    return ChebanCameraPlatform.instance.destory();
  }
}
