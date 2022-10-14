const int CameraTypeImage = 1;
const int CameraTypeVideo = 2;
const int CameraTypeAll = 3;

const int FaceTypeBack = 1;
const int FaceTypeFront = 2;

class CameraModel {
  int width = 0;
  int height = 0;
  int type = CameraTypeImage;
  String origin_file_path = '';
  String thumbnail_file_path = '';

  CameraModel.fromJson(Map<String, dynamic> json) {
    width = json['width'];
    height = json['height'];
    type = json['type'];
    origin_file_path = json['origin_file_path'];
    thumbnail_file_path = json['thumbnail_file_path'];
  }
}
