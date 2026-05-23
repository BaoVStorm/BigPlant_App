import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/auth/auth_session_manager.dart';
import 'core/localization/app_localizations.dart';
import 'core/localization/locale_controller.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

class BigPlantApp extends StatefulWidget {
  const BigPlantApp({super.key});

  @override
  State<BigPlantApp> createState() => _BigPlantAppState();
}

class _BigPlantAppState extends State<BigPlantApp> {
  final LocaleController _localeController = LocaleController();

  void _dismissKeyboard(BuildContext context) {
    final currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      currentFocus.unfocus();
    }
  }

  @override
  void initState() {
    super.initState();
    _localeController.init();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _localeController,
      builder: (context, _) {
        return LocaleScope(
          controller: _localeController,
          child: MaterialApp(
            navigatorKey: AuthSessionManager.navigatorKey,
            debugShowCheckedModeBanner: false,
            title: 'BigPlant',
            theme: AppTheme.light(),
            locale: _localeController.locale,
            supportedLocales: const [Locale('en'), Locale('vi')],
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            initialRoute: AppRouter.splash,
            onGenerateRoute: AppRouter.onGenerateRoute,
            builder: (context, child) {
              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => _dismissKeyboard(context),
                child: child ?? const SizedBox.shrink(),
              );
            },
          ),
        );
      },
    );
  }
}
