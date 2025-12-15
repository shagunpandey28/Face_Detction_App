import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../viewmodels/log_vm.dart';




class LogsPage extends ConsumerWidget {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsState = ref.watch(logVMProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Logs')),
      body: logsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (logs) => ListView.builder(
          itemCount: logs.length,
          itemBuilder: (c, i) {
            final log = logs[i];
            return ListTile(
              leading: Image.memory(base64Decode(log.imageBase64), width: 64, height: 64, fit: BoxFit.cover),
              title: Text('Faces: ${log.faceCount} — ${log.timestamp.toLocal()}'),
              subtitle: Text('Lat: ${log.lat}, Lng: ${log.lng}'),
              trailing: Icon(log.synced ? Icons.check_circle : Icons.access_time, color: log.synced ? Colors.green : Colors.red),
            );
          },
        ),
      ),
    );
  }
}
