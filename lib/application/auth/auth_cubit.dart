// lib/application/auth/auth_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/remote/auth_api_client.dart';
import '../../domain/entities/local_user.dart';
import '../../domain/usecases/auth/delete_account_use_case.dart';
import '../../domain/usecases/auth/request_password_reset_use_case.dart';
import '../../domain/usecases/auth/request_phone_change_otp_use_case.dart';
import '../../domain/usecases/auth/request_phone_otp_use_case.dart';
import '../../domain/usecases/auth/sign_in_use_case.dart';
import '../../domain/usecases/auth/sign_out_use_case.dart';
import '../../domain/usecases/auth/update_email_use_case.dart';
import '../../domain/usecases/auth/upgrade_guest_user_use_case.dart';
import '../../domain/usecases/auth/verify_phone_change_otp_use_case.dart';
import '../../domain/usecases/auth/verify_phone_otp_use_case.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final UpgradeGuestUserUseCase upgradeGuestUserUseCase;
  final SignInUseCase signInUseCase;
  final SignOutUseCase signOutUseCase;
  final RequestPhoneOtpUseCase? requestPhoneOtpUseCase;
  final VerifyPhoneOtpUseCase? verifyPhoneOtpUseCase;
  final RequestPasswordResetUseCase? requestPasswordResetUseCase;
  final DeleteAccountUseCase? deleteAccountUseCase;
  final UpdateEmailUseCase? updateEmailUseCase;
  final RequestPhoneChangeOtpUseCase? requestPhoneChangeOtpUseCase;
  final VerifyPhoneChangeOtpUseCase? verifyPhoneChangeOtpUseCase;

  LocalUser _currentUser;

  AuthCubit({
    required LocalUser initialUser,
    required this.upgradeGuestUserUseCase,
    required this.signInUseCase,
    required this.signOutUseCase,
    this.requestPhoneOtpUseCase,
    this.verifyPhoneOtpUseCase,
    this.requestPasswordResetUseCase,
    this.deleteAccountUseCase,
    this.updateEmailUseCase,
    this.requestPhoneChangeOtpUseCase,
    this.verifyPhoneChangeOtpUseCase,
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

  Future<void> requestPhoneOtp(String phoneNumber) async {
    emit(const AuthLoading());
    try {
      if (requestPhoneOtpUseCase == null) {
        throw AuthApiException('Phone OTP service is not available');
      }
      await requestPhoneOtpUseCase!(phoneNumber: phoneNumber);
      emit(AuthOtpRequested(phoneNumber));
    } on RateLimitException catch (e) {
      emit(AuthRateLimited(e.message));
    } on OtpExpiredException catch (e) {
      emit(AuthOtpExpired(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> verifyPhoneOtp(String phoneNumber, String otpCode) async {
    emit(const AuthLoading());
    try {
      if (verifyPhoneOtpUseCase == null) {
        throw AuthApiException('Phone OTP service is not available');
      }
      final updatedUser = await verifyPhoneOtpUseCase!(
        localUserId: _currentUser.id,
        phoneNumber: phoneNumber,
        otpCode: otpCode,
      );
      _currentUser = updatedUser;
      emit(AuthSuccess(updatedUser, message: 'Phone verified and account linked successfully!'));
    } on RateLimitException catch (e) {
      emit(AuthRateLimited(e.message));
    } on OtpExpiredException catch (e) {
      emit(AuthOtpExpired(e.message));
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

  Future<void> requestPasswordReset(String email) async {
    emit(const AuthLoading());
    try {
      if (requestPasswordResetUseCase == null) {
        throw AuthApiException('Password reset service is not available');
      }
      await requestPasswordResetUseCase!(email: email);
      emit(AuthPasswordResetSent(
        email,
        message: 'Password reset instructions sent to your email.',
      ));
    } on RateLimitException catch (e) {
      emit(AuthRateLimited(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> deleteAccount() async {
    emit(const AuthLoading());
    try {
      if (deleteAccountUseCase == null) {
        throw AuthApiException('Account deletion service is not available');
      }
      final guestUser = await deleteAccountUseCase!(currentUserId: _currentUser.id);
      _currentUser = guestUser;
      emit(AuthSuccess(guestUser, message: 'Account deleted successfully.'));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> updateEmail(String newEmail) async {
    emit(const AuthLoading());
    try {
      if (updateEmailUseCase == null) {
        throw AuthApiException('Update email service is not available');
      }
      final updatedUser = await updateEmailUseCase!(
        currentUserId: _currentUser.id,
        newEmail: newEmail,
      );
      _currentUser = updatedUser;
      emit(AuthSuccess(updatedUser, message: 'Email updated successfully!'));
    } on RateLimitException catch (e) {
      emit(AuthRateLimited(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> requestPhoneChangeOtp(String newPhoneNumber) async {
    emit(const AuthLoading());
    try {
      if (requestPhoneChangeOtpUseCase == null) {
        throw AuthApiException('Phone OTP service is not available');
      }
      await requestPhoneChangeOtpUseCase!(newPhoneNumber: newPhoneNumber);
      emit(AuthOtpRequested(newPhoneNumber));
    } on RateLimitException catch (e) {
      emit(AuthRateLimited(e.message));
    } on OtpExpiredException catch (e) {
      emit(AuthOtpExpired(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> verifyPhoneChangeOtp(String newPhoneNumber, String otpCode) async {
    emit(const AuthLoading());
    try {
      if (verifyPhoneChangeOtpUseCase == null) {
        throw AuthApiException('Phone OTP service is not available');
      }
      final updatedUser = await verifyPhoneChangeOtpUseCase!(
        currentUserId: _currentUser.id,
        newPhoneNumber: newPhoneNumber,
        otpCode: otpCode,
      );
      _currentUser = updatedUser;
      emit(AuthSuccess(updatedUser, message: 'Phone number updated successfully!'));
    } on RateLimitException catch (e) {
      emit(AuthRateLimited(e.message));
    } on OtpExpiredException catch (e) {
      emit(AuthOtpExpired(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
