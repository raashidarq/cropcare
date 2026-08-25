import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cropcare/domain/entities/local_user.dart';
import 'package:cropcare/domain/repositories/auth_repository.dart';
import 'package:cropcare/domain/usecases/feedback/submit_feedback_use_case.dart';
import 'package:cropcare/presentation/onboarding/localization/localization_provider.dart';
import 'package:cropcare/presentation/settings/feedback_screen.dart';

class _FakeFeedbackAuthRepository implements AuthRepository {
  String? lastMessage;
  String? lastCategory;

  @override
  Future<void> sendFeedback({
    required String message,
    String? category,
    String? userId,
  }) async {
    lastMessage = message;
    lastCategory = category;
  }

  @override
  Future<LocalUser> deleteAccount({required String currentUserId}) =>
      throw UnimplementedError();

  @override
  Future<String?> getStoredToken() => throw UnimplementedError();

  @override
  Future<LocalUser> loginAndUpgradeGuest({
    required String localUserId,
    required String email,
    required String password,
  }) =>
      throw UnimplementedError();

  @override
  Future<LocalUser> registerAndUpgradeGuest({
    required String localUserId,
    required String email,
    required String password,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> requestPasswordReset({required String email}) =>
      throw UnimplementedError();

  @override
  Future<void> requestPhoneOtp({required String phoneNumber}) =>
      throw UnimplementedError();

  @override
  Future<LocalUser> signOut({required String currentUserId}) =>
      throw UnimplementedError();

  @override
  Future<LocalUser> verifyPhoneOtpAndUpgrade({
    required String localUserId,
    required String phoneNumber,
    required String otpCode,
  }) =>
      throw UnimplementedError();

  @override
  Future<LocalUser> updateEmail({required String currentUserId, required String newEmail}) => throw UnimplementedError();

  @override
  Future<void> requestPhoneChangeOtp({required String newPhoneNumber}) => throw UnimplementedError();

  @override
  Future<LocalUser> verifyPhoneChangeOtp({required String currentUserId, required String newPhoneNumber, required String otpCode}) => throw UnimplementedError();
}

void main() {
  late _FakeFeedbackAuthRepository fakeRepository;
  late SubmitFeedbackUseCase submitFeedbackUseCase;

  setUp(() {
    fakeRepository = _FakeFeedbackAuthRepository();
    submitFeedbackUseCase = SubmitFeedbackUseCase(fakeRepository);
  });

  Widget createTestWidget() {
    return MaterialApp(
      home: LocalizationProvider(
        languageCode: 'en',
        child: FeedbackScreen(
          submitFeedbackUseCase: submitFeedbackUseCase,
        ),
      ),
    );
  }

  testWidgets('FeedbackScreen renders elements and validates empty input', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Feedback & Suggestions'), findsOneWidget);
    expect(find.byKey(const Key('feedback_category_dropdown')), findsOneWidget);
    expect(find.byKey(const Key('feedback_message_field')), findsOneWidget);
    expect(find.byKey(const Key('feedback_submit_button')), findsOneWidget);

    // Tap submit with empty message
    await tester.tap(find.byKey(const Key('feedback_submit_button')));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a message before submitting.'), findsOneWidget);
    expect(fakeRepository.lastMessage, isNull);
  });

  testWidgets('FeedbackScreen submits message successfully', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('feedback_message_field')),
      'Please add more disease guides for Chili.',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('feedback_submit_button')));
    await tester.pumpAndSettle();

    expect(
      fakeRepository.lastMessage,
      equals('Please add more disease guides for Chili.'),
    );
    expect(fakeRepository.lastCategory, equals('general'));
  });
}
