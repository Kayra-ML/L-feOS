import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/app_settings.dart';
import 'core/theme.dart';
import 'providers/chat_provider.dart';
import 'providers/journal_provider.dart';
import 'providers/note_provider.dart';
import 'providers/task_provider.dart';
import 'screens/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR');
  runApp(const LifeOSApp());
}

class LifeOSApp extends StatelessWidget {
  const LifeOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppSettings()..load(),
      child: Builder(
        builder: (context) {
          final settings = context.watch<AppSettings>();
          if (!settings.isLoaded) {
            return const MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(
                backgroundColor: AppColors.bg,
                body: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          return MultiProvider(
            providers: [
              Provider<ApiClient>(create: (ctx) => ApiClient(ctx.read<AppSettings>())),
              ChangeNotifierProvider(create: (ctx) => TaskProvider(ctx.read<ApiClient>())),
              ChangeNotifierProvider(create: (ctx) => JournalProvider(ctx.read<ApiClient>())),
              ChangeNotifierProvider(create: (ctx) => NoteProvider(ctx.read<ApiClient>())),
              ChangeNotifierProvider(create: (ctx) => ChatProvider(ctx.read<ApiClient>())),
            ],
            child: MaterialApp(
              title: 'LifeOS',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.dark,
              darkTheme: AppTheme.dark,
              themeMode: ThemeMode.dark,
              home: const HomeShell(),
            ),
          );
        },
      ),
    );
  }
}
