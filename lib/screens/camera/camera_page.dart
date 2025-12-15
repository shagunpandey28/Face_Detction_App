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
  late CameraVM cameraVM;

  @override
  void initState() {
    super.initState();
    cameraVM = ref.read(cameraVMProvider.notifier);
    _initAll();
  }

  Future<void> _initAll() async {
    cameras = await availableCameras();
    await cameraVM.initCamera(cameras);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    cameraVM.disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final camState = ref.watch(cameraVMProvider);
    final controller = cameraVM.controller;

    // Show loading while controller is not ready
    if (controller == null || !controller.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Build CameraPreview safely
    return Scaffold(
      appBar: AppBar(title: const Text('Camera (Live Face Detection)')),
      body: Stack(
        children: [
          CameraPreview(controller),
          if (camState.faces.isNotEmpty && controller.value.previewSize != null)
            Positioned.fill(
              child: CustomPaint(
                painter: FacePainter(
                  faces: camState.faces,
                  imageSize: Size(
                    controller.value.previewSize!.height,
                    controller.value.previewSize!.width,
                  ),
                ),
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
                    if (controller.value.isTakingPicture) return;
                    try {
                      final file = await controller.takePicture();
                      final bytes = await file.readAsBytes();
                      final base64 = base64Encode(bytes);
                      final faces = camState.faces.length;
                      final pos = camState.position;

                      if (pos != null) {
                        await ref.read(logVMProvider.notifier).addLocal(
                          img: base64,
                          faces: faces,
                          lat: pos.latitude,
                          lng: pos.longitude,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Log saved locally')));
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Location missing')));
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Capture failed: $e')));
                      }
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
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.red;

    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;

    for (final f in faces) {
      final r = Rect.fromLTRB(
        f.boundingBox.left * scaleX,
        f.boundingBox.top * scaleY,
        f.boundingBox.right * scaleX,
        f.boundingBox.bottom * scaleY,
      );
      canvas.drawRect(r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant FacePainter oldDelegate) =>
      oldDelegate.faces != faces;
}
