import 'package:geolocator/geolocator.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

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