import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'services/local_store.dart';
import 'state/app_state.dart';
import 'theme/gata_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_shell.dart';
import 'screens/splash_screen.dart';

bool firebaseReady = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
  } catch (e) {
    debugPrint('Firebase init failed: $e');
    firebaseReady = false;
  }

  final store = await LocalStore.open();
  runApp(GataApp(store: store));
}

class GataApp extends StatelessWidget {
  const GataApp({super.key, required this.store});
  final LocalStore store;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(store),
      child: MaterialApp(
        title: 'Gata',
        debugShowCheckedModeBanner: false,
        theme: GataTheme.theme,
        home: const _Root(),
      ),
    );
  }
}

/// Gates on Firebase auth state, then on AppState profile completion.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snap.data;
        if (user == null) {
          return const LoginScreen(key: ValueKey('login'));
        }
        // Signed in — start Firestore sync then show the app.
        context.read<AppState>().startFirestoreSync();
        return const HomeShell(key: ValueKey('home'));
      },
    );
  }
}
