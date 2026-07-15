import 'package:flutter/material.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/theme/app_theme.dart';
import 'package:maki_app/screens/onboarding_screen.dart';
import 'package:maki_app/screens/expense_entry_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _hasCompletedOnboarding = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: _hasCompletedOnboarding
          ? const ExpenseEntryScreen()
          : OnboardingScreen(
              onCompleted: () {
                setState(() {
                  _hasCompletedOnboarding = true;
                });
              },
            ),
    );
  }
}
