import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported in-app language codes.
const List<String> kSupportedLanguageCodes = [
  'en',
  'es',
  'hi',
  'fr',
  'de',
  'ja',
];

class AppSettingsState {
  final bool isLoaded;
  final bool hapticFeedback;
  final bool darkMode;
  final String languageCode;
  final String? customHomeHeadline;
  final bool newSaveReminders;
  final String userId;

  const AppSettingsState({
    this.isLoaded = false,
    this.hapticFeedback = true,
    this.darkMode = false,
    this.languageCode = 'en',
    this.customHomeHeadline,
    this.newSaveReminders = true,
    this.userId = '',
  });

  ThemeMode get themeMode => darkMode ? ThemeMode.dark : ThemeMode.light;

  Locale get locale => Locale(languageCode);

  AppSettingsState copyWith({
    bool? isLoaded,
    bool? hapticFeedback,
    bool? darkMode,
    String? languageCode,
    String? customHomeHeadline,
    bool clearHomeHeadline = false,
    bool? newSaveReminders,
    String? userId,
  }) {
    return AppSettingsState(
      isLoaded: isLoaded ?? this.isLoaded,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      darkMode: darkMode ?? this.darkMode,
      languageCode: languageCode ?? this.languageCode,
      customHomeHeadline: clearHomeHeadline
          ? null
          : (customHomeHeadline ?? this.customHomeHeadline),
      newSaveReminders: newSaveReminders ?? this.newSaveReminders,
      userId: userId ?? this.userId,
    );
  }
}

class AppSettingsNotifier extends StateNotifier<AppSettingsState> {
  static const String _hapticKey = 'hapticFeedback';
  static const String _darkModeKey = 'darkMode';
  static const String _languageKey = 'languageCode';
  static const String _headlineKey = 'homeHeadline';
  static const String _remindersKey = 'newSaveReminders';
  static const String _userIdKey = 'userId';

  Future<void>? _loadFuture;

  AppSettingsNotifier({bool autoLoad = true}) : super(const AppSettingsState()) {
    if (autoLoad) {
      _loadFuture = load();
    }
  }

  /// Generates a random UUIDv4 string without external dependencies.
  static String generateUuidV4([Random? random]) {
    final rng = random ?? Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant RFC 4122

    String hex(int b) => b.toRadixString(16).padLeft(2, '0');
    final buffer = StringBuffer();
    for (var i = 0; i < 16; i++) {
      if (i == 4 || i == 6 || i == 8 || i == 10) {
        buffer.write('-');
      }
      buffer.write(hex(bytes[i]));
    }
    return buffer.toString();
  }

  /// Ensures preferences are loaded from [SharedPreferences].
  Future<void> ensureLoaded() => _loadFuture ??= load();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final storedLang = prefs.getString(_languageKey);
    final languageCode =
        (storedLang != null && kSupportedLanguageCodes.contains(storedLang))
            ? storedLang
            : 'en';

    final storedHeadline = prefs.getString(_headlineKey);
    final headline = (storedHeadline != null && storedHeadline.trim().isNotEmpty)
        ? storedHeadline
        : null;

    var userId = prefs.getString(_userIdKey) ?? '';
    if (userId.isEmpty) {
      userId = generateUuidV4();
      await prefs.setString(_userIdKey, userId);
    }

    if (!mounted) return;
    state = AppSettingsState(
      isLoaded: true,
      hapticFeedback: prefs.getBool(_hapticKey) ?? true,
      darkMode: prefs.getBool(_darkModeKey) ?? false,
      languageCode: languageCode,
      customHomeHeadline: headline,
      newSaveReminders: prefs.getBool(_remindersKey) ?? true,
      userId: userId,
    );
  }

  Future<void> setHapticFeedback(bool value) async {
    if (value) {
      HapticFeedback.lightImpact();
    }
    state = state.copyWith(hapticFeedback: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hapticKey, value);
  }

  Future<void> setDarkMode(bool value) async {
    if (state.hapticFeedback) {
      HapticFeedback.lightImpact();
    }
    state = state.copyWith(darkMode: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
  }

  Future<void> setLanguageCode(String code) async {
    final normalized = kSupportedLanguageCodes.contains(code) ? code : 'en';
    if (state.hapticFeedback) {
      HapticFeedback.lightImpact();
    }
    state = state.copyWith(languageCode: normalized);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, normalized);
  }

  Future<void> setHomeHeadline(String? headline) async {
    if (state.hapticFeedback) {
      HapticFeedback.lightImpact();
    }
    final trimmed = headline?.trim();
    final prefs = await SharedPreferences.getInstance();
    if (trimmed == null || trimmed.isEmpty) {
      state = state.copyWith(clearHomeHeadline: true);
      await prefs.remove(_headlineKey);
    } else {
      state = state.copyWith(customHomeHeadline: trimmed);
      await prefs.setString(_headlineKey, trimmed);
    }
  }

  Future<void> setNewSaveReminders(bool value) async {
    if (state.hapticFeedback) {
      HapticFeedback.lightImpact();
    }
    state = state.copyWith(newSaveReminders: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_remindersKey, value);
  }
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettingsState>((ref) {
  return AppSettingsNotifier();
});
