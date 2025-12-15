import 'package:hive/hive.dart';

part 'logs_model.g.dart';


@HiveType(typeId: 0)
class LogModel extends HiveObject {
  @HiveField(0)
  String id; // uuid

  @HiveField(1)
  String imageBase64;

  @HiveField(2)
  int faceCount;

  @HiveField(3)
  DateTime timestamp;

  @HiveField(4)
  double lat;

  @HiveField(5)
  double lng;

  @HiveField(6)
  bool synced;

  LogModel({
    required this.id,
    required this.imageBase64,
    required this.faceCount,
    required this.timestamp,
    required this.lat,
    required this.lng,
    this.synced = false,
  });
}
