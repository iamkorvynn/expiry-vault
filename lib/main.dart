import 'package:material_ui/material_ui.dart';

import 'screens/add_edit_screen.dart';
import 'screens/detail_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/notification_service.dart';
import 'services/onboarding_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialise();
  runApp(const ExpiryVaultApp());
}

class ExpiryVaultApp extends StatelessWidget {
  const ExpiryVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ExpiryVault',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: FutureBuilder<bool>(
        future: OnboardingService().isOnboardingDone,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return snapshot.data!
              ? const HomeScreen()
              : const OnboardingScreen();
        },
      ),
      routes: <String, WidgetBuilder>{
        '/home': (_) => const HomeScreen(),
        '/add': (_) => const AddEditScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/detail') {
          final id = settings.arguments as int;
          return MaterialPageRoute<void>(
            builder: (_) => DetailScreen(documentId: id),
          );
        }
        return null;
      },
    );
  }
}
