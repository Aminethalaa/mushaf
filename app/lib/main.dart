import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/printed.dart';
import 'data/quran.dart';
import 'settings.dart';
import 'ui/home_screen.dart';
import 'ui/welcome_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await Settings.load();
  final pages = PageStore();
  unawaited(pages.scan());
  runApp(MushafApp(state: AppState(settings, pages: pages)));
}

/// Settings plus the loaded text of each riwaya, shared by every screen.
class AppState extends ChangeNotifier {
  AppState(this.settings, {PageStore? pages}) : pages = pages ?? PageStore() {
    settings.addListener(notifyListeners);
  }

  final Settings settings;

  /// Downloaded printed pages. Not merged into this notifier: download
  /// progress would rebuild the whole app on every page.
  final PageStore pages;
  final Map<Riwaya, Future<Mushaf>> _mushafs = {};

  Future<Mushaf> mushaf(Riwaya r) => _mushafs.putIfAbsent(r, () => Mushaf.load(r));

  static AppState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_AppScope>()!.notifier!;
}

class _AppScope extends InheritedNotifier<AppState> {
  const _AppScope({required AppState state, required super.child}) : super(notifier: state);
}

class MushafApp extends StatelessWidget {
  const MushafApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return _AppScope(
      state: state,
      child: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          final s = state.settings;
          return MaterialApp(
            title: 'Mushaf',
            debugShowCheckedModeBanner: false,
            locale: Locale(s.language),
            supportedLocales: const [Locale('ar'), Locale('fr')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            themeMode: s.night ? ThemeMode.dark : ThemeMode.light,
            theme: _theme(Brightness.light),
            darkTheme: _theme(Brightness.dark),
            home: s.onboarded ? const HomeScreen() : const WelcomeScreen(),
          );
        },
      ),
    );
  }

  ThemeData _theme(Brightness b) =>
      ThemeData(brightness: b, colorSchemeSeed: const Color(0xFF1B6B4A), useMaterial3: true);
}
