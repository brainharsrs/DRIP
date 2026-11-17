/// Caminhos do app, num lugar só.
abstract final class Routes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const signup = '/signup';
  static const forgot = '/forgot';

  static const discover = '/discover';
  static const explore = '/explore';
  static const wantList = '/want-list';
  static const activity = '/activity';
  static const profile = '/profile';

  static const settings = '/settings';
  static String drop(String id) => '/drop/$id';
  static String brand(String id) => '/brand/$id';
  static String legal(String doc) => '/legal/$doc';
}
