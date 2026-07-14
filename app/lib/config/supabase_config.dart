/// Supabase project connection values.
///
/// These are the project's **public** values: the URL and the `anon`
/// (publishable) key. They are designed to ship inside client apps — the anon
/// key is not a secret, and Row-Level Security on the server is what protects
/// data. (The `service_role` key and the DB password are the real secrets and
/// live only in the Supabase dashboard.)
///
/// Overridable at build time with:
///   --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://rzaglkkgcdtndodmdiwo.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ6YWdsa2tnY2R0bmRvZG1kaXdvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM5NDg4MjAsImV4cCI6MjA5OTUyNDgyMH0.7cR8g912hSgxktQA_ohb4z0cqBg-IlMFcp7h5rhFnvM',
  );
}
