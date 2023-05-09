import 'dart:io';

import 'package:cheban_camera/camera_model.dart';
import 'package:cheban_camera/cheban_camera.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _chebanCameraPlugin = ChebanCamera();

  CameraModel? _cameraModel;

  VideoPlayerController? videoPlayerController;

  @override
  void initState() {
    super.initState();
  }

  _onTackPhoto() async {
    if (videoPlayerController != null) {
      videoPlayerController!.dispose();
      videoPlayerController = null;
    }
    _cameraModel = await _chebanCameraPlugin.pickCamera();
    if (_cameraModel != null) {
      if (_cameraModel!.type == CameraTypeVideo) {
        videoPlayerController =
            VideoPlayerController.file(File(_cameraModel!.origin_file_path));
        await videoPlayerController!.initialize();
        await videoPlayerController!.setLooping(true);
        await videoPlayerController!.play();
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Plugin example app'),
          ),
          body: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  if (_cameraModel != null)
                    Image.file(
                      File(_cameraModel!.type == CameraTypeImage
                          ? _cameraModel!.origin_file_path
                          : _cameraModel!.thumbnail_file_path),
                      width: 300,
                      height:
                          (_cameraModel!.height * 300 / _cameraModel!.height),
                    ),
                  const SizedBox(height: 50),
                  TextButton(
                    onPressed: _onTackPhoto,
                    child: const Text(
                      '拍照',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              if (_cameraModel != null)
                if (_cameraModel!.type == CameraTypeVideo &&
                    videoPlayerController != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      child: GestureDetector(
                        onTap: () {
                          _cameraModel = null;
                          setState(() {});
                        },
                        child: Center(
                          child: AspectRatio(
                            aspectRatio:
                                videoPlayerController!.value.aspectRatio,
                            child: VideoPlayer(videoPlayerController!),
                          ),
                        ),
                      ),
                    ),
                  )
            ],
          )),
    );
  }
}
