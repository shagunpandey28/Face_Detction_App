import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../viewmodels/auth_vm.dart';
import '../../viewmodels/log_vm.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(authVMProvider);
    final name = userState.maybeWhen(data: (u) => u?.name ?? 'User', orElse: () => 'User');

    return Scaffold(
      appBar: AppBar(title: Text('GeoFace Logger — $name')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Open Camera'),
              onPressed: () => Navigator.pushNamed(context, '/camera'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.list),
              label: const Text('Logs'),
              onPressed: () => Navigator.pushNamed(context, '/logs'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.sync),
              label: const Text('Sync Pending'),
              onPressed: () async {
                await ref.read(logVMProvider.notifier).syncPending();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sync finished (check icons).')));
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              child: const Text('Logout'),
              onPressed: () => ref.read(authVMProvider.notifier).logout(),
            ),
          ],
        ),
      ),
    );
  }
}
