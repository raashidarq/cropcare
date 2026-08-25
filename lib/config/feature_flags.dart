// lib/config/feature_flags.dart
//
// Application-wide feature flags for conditional feature rollout and testing.

/// Controls whether Phone OTP authentication is available in the UI.
/// When false, the app provides email-only authentication.
const bool kPhoneAuthEnabled = true;
