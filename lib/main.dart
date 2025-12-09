import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:video_face_detecting_app/screens/auth/login_page.dart';
import 'package:video_face_detecting_app/screens/auth/register_page.dart';
import 'package:video_face_detecting_app/screens/camera/camera_page.dart';
import 'package:video_face_detecting_app/screens/home/home_page.dart';
import 'package:video_face_detecting_app/screens/logs/logs_page.dart';
import 'core/dio_client.dart';
import 'core/config.dart';

import 'viewmodels/auth_vm.dart';
import 'viewmodels/log_vm.dart';// model

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  //Hive.registerAdapter(LogModelAdapter());
  await DioClient.initAuth();

  runApp(const ProviderScope(child: GeoFaceApp()));
}

class GeoFaceApp extends ConsumerWidget {
  const GeoFaceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authVMProvider);
    final isLoggedIn = authState.maybeWhen(data: (u) => u != null, orElse: () => false);

    return MaterialApp(
      title: 'GeoFace Logger',
      theme: ThemeData(primarySwatch: Colors.blue),
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
