import 'dart:io';

import 'package:cheban_camera/camera_model.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:cheban_camera/cheban_camera.dart';

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

  @override
  void initState() {
    super.initState();
  }

  _onTackPhoto() async {
    _cameraModel = await _chebanCameraPlugin.pickCamera(
      sourceType: CameraTypeImage,
      faceType: FaceTypeFront,
    );
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
          body: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              if (_cameraModel != null)
                Image.file(
                  File(_cameraModel!.type == CameraTypeImage
                      ? _cameraModel!.origin_file_path
                      : _cameraModel!.thumbnail_file_path),
                  width: 300,
                  height: (_cameraModel!.height * 300 / _cameraModel!.height),
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
          )),
    );
  }
}
