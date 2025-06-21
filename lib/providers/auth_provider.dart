import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../business_logic/auth_logic.dart';

part 'auth_provider.g.dart';

@riverpod
class Authentication extends _$Authentication {
  @override
  Future<bool> build() async {
    return await AuthLogic.isAuthenticated();
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await AuthLogic.signIn(email, password);
      state = const AsyncValue.data(true);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> signUp(String email, String password, String name) async {
    state = const AsyncValue.loading();
    try {
      await AuthLogic.signUp(email, password, name);
      state = const AsyncValue.data(true);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await AuthLogic.signOut();
      state = const AsyncValue.data(false);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await AuthLogic.isAuthenticated());
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}