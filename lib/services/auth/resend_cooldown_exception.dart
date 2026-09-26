/* This is a special error that gets thrown when the user asks for a new
verification code too soon after the last one. It carries the message
to show and how many seconds are left before they can try again, so the
screen can show a countdown instead of just a plain error. Both the
sign up screen and the forgot password screen use this same error. */
class ResendCooldownException implements Exception {
  ResendCooldownException(this.message, this.waitSeconds);

  final String message;
  final int waitSeconds;

  @override
  String toString() => message;
}
