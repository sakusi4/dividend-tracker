import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';
import 'screens/splash_screen.dart';
import 'screens/portfolio_screen.dart';
import 'screens/input_form_screen.dart';
import 'screens/result_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DividendTrackerApp());
}

class DividendTrackerApp extends StatelessWidget {
  const DividendTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: CupertinoApp(
        debugShowCheckedModeBanner: false,
        theme: const CupertinoThemeData(brightness: Brightness.light),
        initialRoute: SplashScreen.route,
        routes: {
          SplashScreen.route: (_) => const SplashScreen(),
          PortfolioScreen.route: (_) => const PortfolioScreen(),
          InputFormScreen.route: (_) => const InputFormScreen(),
          ResultScreen.route: (_) => const ResultScreen(),
        },
      ),
    );
  }
}