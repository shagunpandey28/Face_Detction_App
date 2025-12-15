import 'dart:ui';
import 'dart:typed_data';
import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // legacy की जगह नया import
import 'package:flutter_riverpod/legacy.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:location/location.dart';
import '../viewmodels/log_vm.dart';

final cameraVMProvider = StateNotifierProvider<CameraVM, CameraState>((ref) {
  return CameraVM(ref);
});

class CameraState {
  final List<Face> faces;
  final Position? position;

  CameraState({
    this.faces = const [],
    this.position,
  });

  CameraState copyWith({
    List<Face>? faces,
    Position? position,
  }) {
    return CameraState(
      faces: faces ?? this.faces,
      position: position ?? this.position,
    );
  }
}

class CameraVM extends StateNotifier<CameraState> {
  final Ref ref;
  final FaceDetector detector = FaceDetector(
    options: FaceDetectorOptions(performanceMode: FaceDetectorMode.fast),
  );
  CameraController? controller;
  bool isControllerInitialized = false;
  Location location = Location();

  bool _processing = false;

  CameraVM(this.ref) : super(CameraState());

  /// Initialize camera and start image stream
  Future<void> initCamera(List<CameraDescription> cameras) async {
    if (cameras.isEmpty) return;

    controller = CameraController(
      cameras[0],
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await controller!.initialize();
    if (!mounted) return;

    // setState(() {
    //   isControllerInitialized = true;
    // });
    await controller!.startImageStream(_processCameraImage);

    await _getLocation();
  }


  /// Get location + enable live updates
  Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          print("User denied enabling location service");
          return;
        }
      }

      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted &&
            permissionGranted != PermissionStatus.grantedLimited) {
          print("User denied location permission");
          return;
        }
      }

      // First location
      final LocationData locationData = await location.getLocation();

      state = state.copyWith(
        position: Position(
          latitude: locationData.latitude!,
          longitude: locationData.longitude!,
          timestamp: DateTime.now(),
          accuracy: locationData.accuracy ?? 0,
          altitude: locationData.altitude ?? 0,
          speed: locationData.speed ?? 0,
          speedAccuracy: 0,
          heading: locationData.heading ?? 0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        ),
      );

      // Live location updates (highly recommended)
      location.onLocationChanged.listen((LocationData currentLocation) {
        if (currentLocation.latitude != null && currentLocation.longitude != null) {
          state = state.copyWith(
            position: Position(
              latitude: currentLocation.latitude!,
              longitude: currentLocation.longitude!,
              timestamp: DateTime.now(),
              accuracy: currentLocation.accuracy ?? 0,
              altitude: currentLocation.altitude ?? 0,
              speed: currentLocation.speed ?? 0,
              speedAccuracy: 0,
              heading: currentLocation.heading ?? 0,
              altitudeAccuracy: 0.0,
              headingAccuracy: 0.0,
            ),
          );
        }
      });
    } catch (e) {
      print("Location Error: $e");
    }
  }

  Future<void> refreshLocation() async {
    await _getLocation();
  }

  /// Process camera image – ONLY for face detection (no location here)
  Future<void> _processCameraImage(CameraImage image) async {
    if (_processing) return;
    _processing = true;

    try {
      if (image.format.group != ImageFormatGroup.yuv420 &&
          image.format.group != ImageFormatGroup.bgra8888) {
        return;
      }

      final inputImage = _convertCameraImageSafe(
          image, controller!.description.sensorOrientation);

      final faces = await detector.processImage(inputImage);

      state = state.copyWith(faces: faces); // Smooth face update
    } catch (e) {
      debugPrint("Error in _processCameraImage: $e");
    } finally {
      _processing = false;
    }
  }

  /// Convert CameraImage to InputImage
  InputImage _convertCameraImageSafe(CameraImage image, int rotation) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());

    final imageRotation =
        InputImageRotationValue.fromRawValue(rotation) ?? InputImageRotation.rotation0deg;

    final InputImageFormat inputImageFormat = image.format.group == ImageFormatGroup.yuv420
        ? InputImageFormat.nv21
        : InputImageFormat.bgra8888;

    final int bytesPerRow =
    image.planes.isNotEmpty ? image.planes[0].bytesPerRow : image.width;

    final metadata = InputImageMetadata(
      size: imageSize,
      rotation: imageRotation,
      format: inputImageFormat,
      bytesPerRow: bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  /// Capture image and save
  Future<void> captureAndSave() async {
    if (controller == null || !controller!.value.isInitialized) return;

    try {
      final file = await controller!.takePicture();
      final bytes = await file.readAsBytes();
      final base64 = base64Encode(bytes);

      final facesCount = state.faces.length;
      final pos = state.position;

      if (pos != null) {
        await ref.read(logVMProvider.notifier).addLocal(
          img: base64,
          faces: facesCount,
          lat: pos.latitude,
          lng: pos.longitude,
        );
      } else {
        print("Location was null during capture");
      }
    } catch (e) {
      if (kDebugMode) print("Error in captureAndSave: $e");
    }
  }

  /// Dispose everything
  Future<void> disposeController() async {
    await controller?.stopImageStream();
    await controller?.dispose();
    await detector.close();
  }
}