import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get appName => dotenv.env['APP_NAME'] ?? 'Save Later';
  static String get supportEmail => dotenv.env['SUPPORT_EMAIL'] ?? 'support@savelater.app';
  static String get howToUrl => dotenv.env['HOW_TO_URL'] ?? 'https://savelater.app/howto';
  static String get privacyPolicyUrl => dotenv.env['PRIVACY_POLICY_URL'] ?? 'https://savelater.app/privacy';
  static String get termsOfServiceUrl => dotenv.env['TERMS_OF_SERVICE_URL'] ?? 'https://savelater.app/terms';
}
