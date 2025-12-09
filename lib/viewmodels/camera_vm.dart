import 'dart:ui';
import 'dart:typed_data';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod/legacy.dart';
import 'package:riverpod/riverpod.dart';

import '../viewmodels/log_vm.dart';


final cameraVMProvider = StateNotifierProvider<CameraVM, CameraState>((ref) {
  return CameraVM(ref);
});

class CameraState {
  final List<Face> faces;
  final Position? position;
  CameraState({this.faces = const [], this.position});
}

class CameraVM extends StateNotifier<CameraState> {
  final Ref ref;
  final FaceDetector detector = FaceDetector(options: FaceDetectorOptions(performanceMode: FaceDetectorMode.fast));
  CameraController? controller;

  CameraVM(this.ref) : super(CameraState());

  Future<void> initCamera(List<CameraDescription> cameras) async {
    if (cameras.isEmpty) return;
    controller = CameraController(cameras[0], ResolutionPreset.medium, enableAudio: false);
    await controller!.initialize();
    controller!.startImageStream(_processCameraImage);
  }

  bool _processing = false;

  Future<void> _processCameraImage(CameraImage image) async {
    if (_processing) return;
    _processing = true;

    try {
      // convert to InputImage for ML Kit
      final inputImage = _convertCameraImage(image, controller!.description.sensorOrientation);
      final faces = await detector.processImage(inputImage);
      final pos = await Geolocator.getCurrentPosition();
      state = CameraState(faces: faces, position: pos);
    } catch (e) {
      // ignore
    } finally {
      _processing = false;
    }
  }

  // Convert CameraImage to InputImage (NV21/YUV). Implementation below:
  InputImage _convertCameraImage(CameraImage image, int rotation) {
    // collect bytes
    final WriteBuffer allBytes = WriteBuffer();
    for (final plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    // image size
    final Size imageSize = Size(
      image.width.toDouble(),
      image.height.toDouble(),
    );

    // rotation & format mapping (use provided helpers from the package)
    final imageRotation =
        InputImageRotationValue.fromRawValue(rotation) ?? InputImageRotation.rotation0deg;

    final inputImageFormat =
        InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;

    // mlkit now only needs bytesPerRow (you can take from first plane)
    final int bytesPerRow = image.planes.isNotEmpty ? image.planes[0].bytesPerRow : image.width;

    final metadata = InputImageMetadata(
      size: imageSize,
      rotation: imageRotation,
      format: inputImageFormat,
      bytesPerRow: bytesPerRow,
    );

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: metadata,
    );
  }




  Future<void> captureAndSave(CameraImage image) async {
    // flatten bytes to jpg or use controller.takePicture when wanting higher quality.
    // We'll convert YUV CameraImage to JPEG by using controller.takePicture for simplicity when possible.
    // But if streaming only, fallback to encoding current preview bytes: here we attempt controller.takePicture()
    try {
      final file = await controller!.takePicture();
      final bytes = await file.readAsBytes();
      final base64 = base64Encode(bytes);
      final faces = state.faces.length;
      final pos = state.position!;
      await ref.read(logVMProvider.notifier).addLocal(img: base64, faces: faces, lat: pos.latitude, lng: pos.longitude);
    } catch (e) {
      // fallback: no-op or implement conversion from CameraImage to jpeg
    }
  }

  Future<void> disposeController() async {
    await controller?.stopImageStream();
    await controller?.dispose();
    detector.close();
  }
}
