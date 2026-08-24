// lib/application/auth/auth_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/remote/auth_api_client.dart';
import '../../domain/entities/local_user.dart';
import '../../domain/usecases/auth/sign_in_use_case.dart';
import '../../domain/usecases/auth/sign_out_use_case.dart';
import '../../domain/usecases/auth/upgrade_guest_user_use_case.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final UpgradeGuestUserUseCase upgradeGuestUserUseCase;
  final SignInUseCase signInUseCase;
  final SignOutUseCase signOutUseCase;

  LocalUser _currentUser;

  AuthCubit({
    required LocalUser initialUser,
    required this.upgradeGuestUserUseCase,
    required this.signInUseCase,
    required this.signOutUseCase,
  })  : _currentUser = initialUser,
        super(AuthInitial(initialUser));

  LocalUser get currentUser => _currentUser;

  Future<void> registerAndUpgrade({
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading());
    try {
      final updatedUser = await upgradeGuestUserUseCase(
        localUserId: _currentUser.id,
        email: email,
        password: password,
      );
      _currentUser = updatedUser;
      emit(AuthSuccess(updatedUser, message: 'Account created and linked successfully!'));
    } on RateLimitException catch (e) {
      emit(AuthRateLimited(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signInAndUpgrade({
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading());
    try {
      final updatedUser = await signInUseCase(
        localUserId: _currentUser.id,
        email: email,
        password: password,
      );
      _currentUser = updatedUser;
      emit(AuthSuccess(updatedUser, message: 'Signed in successfully!'));
    } on RateLimitException catch (e) {
      emit(AuthRateLimited(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signOut() async {
    emit(const AuthLoading());
    try {
      final guestUser = await signOutUseCase(currentUserId: _currentUser.id);
      _currentUser = guestUser;
      emit(AuthSuccess(guestUser, message: 'Signed out successfully.'));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
