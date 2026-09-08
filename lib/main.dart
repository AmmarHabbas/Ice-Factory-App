import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/light_theme.dart';
import 'core/providers/database_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: IceCubeApp(),
    ),
  );
}

class IceCubeApp extends ConsumerWidget {
  const IceCubeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Eagerly initialize local database & seed initial mock data
    ref.read(databaseProvider);

    return MaterialApp.router(
      title: 'Fawares Al Sham - Ice Cube Flow',
      debugShowCheckedModeBanner: false,
      theme: getLightTheme(),
      routerConfig: appRouter,
    );
  }
}
