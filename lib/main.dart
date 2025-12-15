import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/logs_model.dart';

import 'screens/auth/login_page.dart';
import 'screens/auth/register_page.dart';
import 'screens/camera/camera_page.dart';
import 'screens/home/home_page.dart';
import 'screens/logs/logs_page.dart';

import 'viewmodels/auth_vm.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(LogModelAdapter());


  await Hive.openBox<LogModel>('logs');

  runApp(const ProviderScope(child: GeoFaceApp()));
}

class GeoFaceApp extends ConsumerWidget {
  const GeoFaceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authVMProvider);
    final isLoggedIn =
    authState.maybeWhen(data: (u) => u != null, orElse: () => false);

    return MaterialApp(
      title: 'GeoFace Logger',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      initialRoute: isLoggedIn ? '/home' : '/login',
      routes: {
        '/login': (_) => const LoginPage(),
        '/register': (_) => const RegisterPage(),
        '/home': (_) => const HomePage(),
        '/camera': (_) => const CameraPage(),
        '/logs': (_) => const LogsPage(),
      },
    );
  }
}
