import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'state/app_state.dart';
import 'screens/splash_screen.dart';
import 'screens/portfolio_screen.dart';
import 'screens/input_form_screen.dart';
import 'screens/result_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(
    fileName: kReleaseMode ? '.env.production' : '.env.development'
  );

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