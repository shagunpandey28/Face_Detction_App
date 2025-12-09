import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../../viewmodels/camera_vm.dart';
import '../../viewmodels/log_vm.dart';


class CameraPage extends ConsumerStatefulWidget {
  const CameraPage({super.key});

  @override
  ConsumerState<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends ConsumerState<CameraPage> {
  List<CameraDescription> cameras = [];

  @override
  void initState() {
    super.initState();
    initAll();
  }

  Future<void> initAll() async {
    cameras = await availableCameras();
    await ref.read(cameraVMProvider.notifier).initCamera(cameras);
    setState(() {});
  }

  @override
  void dispose() {
    ref.read(cameraVMProvider.notifier).disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final camState = ref.watch(cameraVMProvider);
    final controller = ref.watch(cameraVMProvider.notifier).controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Camera (Live Face Detection)')),
      body: Stack(
        children: [
          CameraPreview(controller),
          // overlay bounding boxes
          Positioned.fill(
            child: CustomPaint(
              painter: FacePainter(faces: camState.faces, imageSize: Size(controller.value.previewSize!.height, controller.value.previewSize!.width)),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.camera),
                  label: const Text('Capture'),
                  onPressed: () async {
                    try {
                      final file = await controller.takePicture();
                      final bytes = await file.readAsBytes();
                      final base64 = base64Encode(bytes);
                      final faces = camState.faces.length;
                      final pos = camState.position;
                      if (pos != null) {
                        await ref.read(logVMProvider.notifier).addLocal(img: base64, faces: faces, lat: pos.latitude, lng: pos.longitude);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Log saved locally')));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location missing')));
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Capture failed: $e')));
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FacePainter extends CustomPainter {
  final List<Face> faces;
  final Size imageSize;
  FacePainter({required this.faces, required this.imageSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 2.0..color = Colors.red;
    for (final f in faces) {
      final r = Rect.fromLTRB(
        f.boundingBox.left,
        f.boundingBox.top,
        f.boundingBox.right,
        f.boundingBox.bottom,
      );
      // NOTE: Coordinates need scaling depending on preview orientation/size.
      canvas.drawRect(r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant FacePainter oldDelegate) => oldDelegate.faces != faces;
}
