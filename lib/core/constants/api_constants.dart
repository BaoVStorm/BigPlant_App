import 'app_globals.dart';

class ApiConstants {
  static const String apiKeyLocal = 'http://127.0.0.1:3104/';
  static const String apiKeyServer = 'http://35.77.221.203:3104/';

  static String get baseUrl =>
      AppGlobals.useLocalApi ? apiKeyLocal : apiKeyServer;
}
