import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app_router.dart';
import 'app/theme_provider.dart';
import 'config/supabase_config.dart';
import 'features/auth/application/auth_provider.dart';
import 'features/auth/data/auth_gateway.dart';
import 'features/auth/data/profile_repository.dart';
import 'features/cart/presentation/cart_provider.dart';
import 'features/catalog/data/product_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        Provider<ProductRepository>(create: (_) => ProductRepository()),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(
            authGateway: SupabaseAuthGateway(),
            profileRepository: SupabaseProfileRepository(),
          )..start(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createAppRouter(context.read<AuthProvider>());
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final textTheme = GoogleFonts.lexendTextTheme();

    final lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2D3142),
        primary: const Color(0xFF2D3142),
        secondary: const Color(0xFFEF8354),
        brightness: Brightness.light,
      ),
      textTheme: textTheme,
    );

    final darkTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFBFC0C0),
        primary: const Color(0xFFBFC0C0),
        secondary: const Color(0xFFEF8354),
        brightness: Brightness.dark,
      ),
      textTheme: textTheme,
    );

    return MaterialApp.router(
      title: 'AR Home',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeProvider.themeMode,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
