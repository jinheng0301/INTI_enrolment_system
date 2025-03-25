import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inti/common/provider/auth_provider.dart';
import 'package:inti/common/utils/color.dart';
import 'package:inti/common/widgets/error.dart';
import 'package:inti/common/widgets/loader.dart';
import 'package:inti/firebase_options.dart';
import 'package:inti/router.dart';
import 'package:inti/screens_&_features/auth/screens/login_screen.dart';
import 'package:inti/screens_&_features/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: backgroundColor,
        appBarTheme: AppBarTheme(color: appBarColor),
      ),
      onGenerateRoute: (settings) => onGenerateRoute(settings),
      home: authState.when(
        data: (user) {
          return user != null ? DashboardScreen() : LoginScreen();
        },
        loading: () => const Scaffold(body: Loader()),
        error:
            (error, _) => Scaffold(body: ErrorScreen(error: error.toString())),
      ),
    );
  }
}
