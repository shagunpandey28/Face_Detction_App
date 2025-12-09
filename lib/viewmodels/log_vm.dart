

import 'package:riverpod/legacy.dart';
import 'package:riverpod/riverpod.dart';

import '../models/logs_model.dart';
import '../services/log_services.dart';

final logVMProvider = StateNotifierProvider<LogVM, AsyncValue<List<LogModel>>>((ref) {
  return LogVM();
});

class LogVM extends StateNotifier<AsyncValue<List<LogModel>>> {
  final _service = LogService();
  LogVM(): super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    await _service.init();
    load();
  }

  Future<void> load() async {
    final all = _service.getAll();
    state = AsyncValue.data(all);
  }

  Future<void> addLocal({required String img, required int faces, required double lat, required double lng}) async {
    await _service.addLocal(
      imageBase64: img,
      faceCount: faces,
      timestamp: DateTime.now(),
      lat: lat,
      lng: lng,
    );
    load();
  }

  Future<void> syncPending() async {
    await _service.syncPending();
    load();
  }
}
