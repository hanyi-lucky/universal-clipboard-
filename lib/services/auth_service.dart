import '../services/cloudbase_service.dart';

class AuthService {
  final CloudBaseService _cloud;

  AuthService(this._cloud);

  Future<void> signInAnonymously() async {
    await _cloud.signInAnonymously();
  }

  bool get isLoggedIn => _cloud.isLoggedIn;

  String get userId {
    if (_cloud.openId == null) throw StateError('Not signed in');
    return _cloud.openId!;
  }
}
