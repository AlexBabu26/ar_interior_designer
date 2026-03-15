import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app_router.dart';
import 'app/app_theme.dart';
import 'config/app_config.dart';
import 'config/supabase_config.dart';
import 'features/auth/application/auth_provider.dart';
import 'features/auth/data/auth_gateway.dart';
import 'features/auth/data/profile_repository.dart';
import 'features/cart/data/cart_repository.dart';
import 'features/cart/presentation/cart_provider.dart';
import 'features/catalog/data/product_repository.dart';
import 'features/image_generation/data/generated_image_repository.dart';
import 'features/orders/data/order_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  // In debug, load product 3D models from Dart Frog so AR view can find them.
  if (kDebugMode) {
    productModelsBaseUrl = 'http://localhost:8080';
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<ProductRepository>(create: (_) => SupabaseProductRepository()),
        Provider<CartRepository>(create: (_) => SupabaseCartRepository()),
        Provider<OrderRepository>(create: (_) => SupabaseOrderRepository()),
        Provider<GeneratedImageRepository>(
          create: (_) => SupabaseGeneratedImageRepository(),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(
            authGateway: SupabaseAuthGateway(),
            profileRepository: SupabaseProfileRepository(),
          )..start(),
        ),
        ChangeNotifierProxyProvider2<
          CartRepository,
          AuthProvider,
          CartProvider
        >(
          create: (_) => CartProvider(),
          update: (_, cartRepository, authProvider, cartProvider) {
            final provider = cartProvider ?? CartProvider();
            provider.configure(
              repository: cartRepository,
              authProvider: authProvider,
            );
            return provider;
          },
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
    return MaterialApp.router(
      title: 'AR Home',
      theme: AppTheme.light(),
      themeAnimationDuration: Duration.zero,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
