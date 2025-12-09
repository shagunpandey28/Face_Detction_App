import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';
import '../core/dio_client.dart';
import '../models/logs_model.dart';

class LogService {
  static const boxName = 'logs';

  Future<void> init() async {
    await Hive.openBox<LogModel>(boxName);
  }

  Future<void> addLocal({
    required String imageBase64,
    required int faceCount,
    required DateTime timestamp,
    required double lat,
    required double lng,
  }) async {
    final box = Hive.box<LogModel>(boxName);
    final id = Uuid().v4();
    final model = LogModel(
      id: id,
      imageBase64: imageBase64,
      faceCount: faceCount,
      timestamp: timestamp,
      lat: lat,
      lng: lng,
      synced: false,
    );
    await box.put(id, model);
  }

  List<LogModel> getAll() {
    final box = Hive.box<LogModel>(boxName);
    return box.values.toList();
  }

  Future<void> syncPending() async {
    final box = Hive.box<LogModel>(boxName);
    final pending = box.values.where((e) => !e.synced).toList();
    final dio = DioClient.instance;

    for (final log in pending) {
      final body = {
        "image": log.imageBase64,
        "face_count": log.faceCount,
        "timestamp": log.timestamp.toUtc().toIso8601String(),
        "lat": log.lat,
        "lng": log.lng,
        "roi": [], // optionally include ROI
      };
      try {
        await dio.post('/logs', data: body);
        log.synced = true;
        await log.save();
      } catch (e) {
        // keep it pending; log error if needed
      }
    }
  }
}
