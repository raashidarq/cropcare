// lib/application/auth/auth_state.dart

import '../../domain/entities/local_user.dart';

abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  final LocalUser user;

  const AuthInitial(this.user);
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthSuccess extends AuthState {
  final LocalUser user;
  final String message;

  const AuthSuccess(this.user, {this.message = ''});
}

class AuthRateLimited extends AuthState {
  final String message;

  const AuthRateLimited(this.message);
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);
}
