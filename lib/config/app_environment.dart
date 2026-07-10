import 'package:flutter/services.dart';

class AppEnvironment {
  const AppEnvironment({
    required this.enableRemoteSync,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.googleClientId,
    required this.googleServerClientId,
  });

  final bool enableRemoteSync;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String googleClientId;
  final String googleServerClientId;

  bool get canInitializeSupabase =>
      enableRemoteSync &&
      supabaseUrl.trim().isNotEmpty &&
      supabaseAnonKey.trim().isNotEmpty;

  factory AppEnvironment.fromEnvironment() {
    return const AppEnvironment(
      enableRemoteSync: bool.fromEnvironment(
        'ENABLE_REMOTE_SYNC',
        defaultValue: false,
      ),
      supabaseUrl: String.fromEnvironment('SUPABASE_URL', defaultValue: ''),
      supabaseAnonKey: String.fromEnvironment(
        'SUPABASE_ANON_KEY',
        defaultValue: '',
      ),
      googleClientId: String.fromEnvironment(
        'GOOGLE_CLIENT_ID',
        defaultValue: '',
      ),
      googleServerClientId: String.fromEnvironment(
        'GOOGLE_SERVER_CLIENT_ID',
        defaultValue: '',
      ),
    );
  }

  static Future<AppEnvironment> load() async {
    final defined = AppEnvironment.fromEnvironment();
    if (defined.canInitializeSupabase) {
      return defined;
    }

    final values = await _loadDotEnvValues();
    if (values.isEmpty) {
      return defined;
    }

    return AppEnvironment(
      enableRemoteSync:
          defined.enableRemoteSync ||
          _parseBool(values['ENABLE_REMOTE_SYNC'] ?? ''),
      supabaseUrl: _firstPresent(defined.supabaseUrl, values['SUPABASE_URL']),
      supabaseAnonKey: _firstPresent(
        defined.supabaseAnonKey,
        values['SUPABASE_ANON_KEY'],
      ),
      googleClientId: _firstPresent(
        defined.googleClientId,
        values['GOOGLE_CLIENT_ID'],
      ),
      googleServerClientId: _firstPresent(
        defined.googleServerClientId,
        values['GOOGLE_SERVER_CLIENT_ID'],
      ),
    );
  }

  static Future<Map<String, String>> _loadDotEnvValues() async {
    try {
      final raw = await rootBundle.loadString('.env');
      final values = <String, String>{};
      for (final line in raw.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) {
          continue;
        }
        final separatorIndex = trimmed.indexOf('=');
        if (separatorIndex <= 0) {
          continue;
        }
        final key = trimmed.substring(0, separatorIndex).trim();
        final value = trimmed.substring(separatorIndex + 1).trim();
        values[key] = _stripQuotes(value);
      }
      return values;
    } catch (_) {
      return const {};
    }
  }

  static String _firstPresent(String defined, String? fallback) {
    final normalized = defined.trim();
    if (normalized.isNotEmpty) {
      return normalized;
    }
    return fallback?.trim() ?? '';
  }

  static bool _parseBool(String value) {
    return value.trim().toLowerCase() == 'true';
  }

  static String _stripQuotes(String value) {
    if (value.length < 2) {
      return value;
    }
    final first = value[0];
    final last = value[value.length - 1];
    if ((first == '"' && last == '"') || (first == "'" && last == "'")) {
      return value.substring(1, value.length - 1);
    }
    return value;
  }
}
