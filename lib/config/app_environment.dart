class AppEnvironment {
  const AppEnvironment({
    required this.enableRemoteSync,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
  });

  final bool enableRemoteSync;
  final String supabaseUrl;
  final String supabaseAnonKey;

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
    );
  }
}
