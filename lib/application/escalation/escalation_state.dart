// lib/application/escalation/escalation_state.dart
//
// States for EscalationCubit.

abstract class EscalationState {
  const EscalationState();
}

class EscalationInitial extends EscalationState {
  const EscalationInitial();
}

class EscalationSharing extends EscalationState {
  const EscalationSharing();
}

class EscalationSharedSuccess extends EscalationState {
  final String shareMessage;

  const EscalationSharedSuccess({required this.shareMessage});
}

class EscalationError extends EscalationState {
  final String error;

  const EscalationError(this.error);
}
