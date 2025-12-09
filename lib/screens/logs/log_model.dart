import 'package:hive/hive.dart';

class LogModel {
  @HiveField(0)
  final String message;

  @HiveField(1)
  final DateTime timestamp;

  LogModel({required this.message, required this.timestamp});
}