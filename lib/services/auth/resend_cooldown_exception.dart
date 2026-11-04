/// Thrown when a new code is requested too soon. Carries the message and
/// the seconds left so the screen can show a countdown.
/// Used by sign up and forgot password.
class ResendCooldownException implements Exception {
  ResendCooldownException(this.message, this.waitSeconds);

  final String message;
  final int waitSeconds;

  @override
  String toString() => message;
}
