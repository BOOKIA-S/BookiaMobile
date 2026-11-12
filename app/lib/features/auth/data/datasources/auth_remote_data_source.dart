typedef AuthPost = Future<Map<String, dynamic>> Function(
  String path, {
  Object? body,
});

/// Accepts ApiClient.post after the shared network branch is integrated.
class AuthRemoteDataSource {
  const AuthRemoteDataSource(this.post);

  final AuthPost post;

  Future<Map<String, dynamic>> login(
    String email,
    String password, {
    bool staff = false,
  }) => post(
    '/auth/login',
    body: {
      'email': email,
      'password': password,
      'client': 'mobile',
      if (staff) 'portal': 'admin',
    },
  );

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) => post(
    '/auth/register',
    body: {
      'name': name,
      'email': email,
      'password': password,
      'client': 'mobile',
    },
  );
}
