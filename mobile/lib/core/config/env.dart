/// Runtime configuration, provided via `--dart-define-from-file=env.json`
/// (see `env.example.json` for the expected keys). Only public/safe values
/// belong here — secrets (Gemini key, Mongo URI, Strava secret, Supabase
/// service role key) live exclusively in the backend's environment.
class Env {
  Env._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// Base URL of the Flask backend, e.g. http://10.0.2.2:5000/api for the
  /// Android emulator talking to a locally running backend.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000/api',
  );

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
