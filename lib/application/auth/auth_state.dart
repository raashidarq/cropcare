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

class AuthOtpExpired extends AuthState {
  final String message;

  const AuthOtpExpired(this.message);
}

class AuthOtpRequested extends AuthState {
  final String phoneNumber;

  const AuthOtpRequested(this.phoneNumber);
}

class AuthPasswordResetSent extends AuthState {
  final String email;
  final String message;

  const AuthPasswordResetSent(this.email, {this.message = ''});
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);
}

