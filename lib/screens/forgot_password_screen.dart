import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth/forgot_password_service.dart';
import '../services/auth/resend_cooldown_exception.dart';
import '../widgets/loading_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _isSendingCode = false;
  bool _searchCompleted = false;
  int _currentStep = 1; // 1: verify code, 2: new password
  late List<TextEditingController> _verificationCodeControllers;
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isResetting = false;
  bool _passwordResetSuccessful = false;
  int _remainingSeconds = 0;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _verificationCodeControllers = List.generate(
      4,
      (index) => TextEditingController(),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _resendTimer?.cancel();
    for (var controller in _verificationCodeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _startResendCooldown(int seconds) {
    _resendTimer?.cancel();
    setState(() => _remainingSeconds = seconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() => _remainingSeconds = 0);
      } else {
        setState(() => _remainingSeconds -= 1);
      }
    });
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+").hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  Future<void> _sendCode({required bool isResend}) async {
    if (_isSendingCode) return;
    setState(() => _isSendingCode = true);
    try {
      await ForgotPasswordService.sendResetCode(_emailController.text.trim());
      if (!mounted) return;
      _startResendCooldown(120);
      setState(() {
        _searchCompleted = true;
        _currentStep = 1;
      });
      if (isResend) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A new code has been sent.')),
        );
      }
    } on ResendCooldownException catch (e) {
      if (!mounted) return;
      _startResendCooldown(e.waitSeconds);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isSendingCode = false);
    }
  }

  Future<void> _handleSearch() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    await _sendCode(isResend: false);
  }

  Future<void> _resetPassword() async {
    if (_isResetting) return;

    final code = _verificationCodeControllers.map((c) => c.text).join();
    if (code.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 4-digit code.')),
      );
      return;
    }

    setState(() => _isResetting = true);
    try {
      await ForgotPasswordService.resetPassword(
        email: _emailController.text.trim(),
        code: code,
        newPassword: _newPasswordController.text,
      );
      if (!mounted) return;
      setState(() => _passwordResetSuccessful = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isResetting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/bg.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: GestureDetector(
                      onTap: () {
                        if (_searchCompleted) {
                          if (_passwordResetSuccessful) {
                            Navigator.of(context).pop();
                          } else if (_currentStep == 2) {
                            setState(() {
                              _currentStep = 1;
                            });
                          } else {
                            _resendTimer?.cancel();
                            setState(() {
                              _searchCompleted = false;
                              _remainingSeconds = 0;
                            });
                          }
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withValues(
                                        alpha: 0.15,
                                      ),
                                      blurRadius: 15,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(25),
                                child: !_searchCompleted
                                    ? _buildSearchForm()
                                    : _passwordResetSuccessful
                                    ? _buildPasswordResetSuccessScreen()
                                    : _currentStep == 1
                                    ? _buildVerificationScreen()
                                    : _buildPasswordResetScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepIndicator(int step, String label) {
    final isActive = step <= (_searchCompleted ? _currentStep + 1 : 1);
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF006837) : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? const Color(0xFF006837) : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _stepIndicator(1, "Email"),
                _stepIndicator(2, "Verify"),
                _stepIndicator(3, "Password"),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            "Forgot Password?",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF006837),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Enter your account's email and we'll\nsend you a code to reset your password.",
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF666666),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.email_outlined,
                  color: Color(0xFF006837),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Find your account",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Please enter your account's\nemail address.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF999999),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
            decoration: InputDecoration(
              hintText: "Email address",
              hintStyle: const TextStyle(
                color: Color(0xFFBBBBBB),
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.email_outlined,
                color: Color(0xFF006837),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF006837),
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: const Color(0xFFFAFAFA),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: LoadingButton(
              isLoading: _isSendingCode,
              onPressed: _handleSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006837),
                disabledBackgroundColor: const Color(
                  0xFF006837,
                ).withValues(alpha: 0.6),
                disabledForegroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                "Send Code",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/contact');
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7F0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0F0E0), width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF006837),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.help_outline,
                      color: Color(0xFF006837),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Need more help?",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Contact our support team\nfor assistance",
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF666666),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFF006837),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationScreen() {
    String formattedTime =
        "${(_remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}";
    final userEmail = _emailController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _stepIndicator(1, "Email"),
              _stepIndicator(2, "Verify"),
              _stepIndicator(3, "Password"),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          "Enter the code",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text(
              "We sent a 4-digit code to ",
              style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
            ),
            Expanded(
              child: Text(
                userEmail,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF006837),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            4,
            (index) => SizedBox(
              width: 50,
              child: TextFormField(
                controller: _verificationCodeControllers[index],
                maxLength: 1,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF006837),
                ),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFFDDDDDD),
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFFDDDDDD),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF006837),
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty && index < 3) {
                    FocusScope.of(context).nextFocus();
                  } else if (value.isEmpty && index > 0) {
                    FocusScope.of(context).previousFocus();
                  }
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Didn't receive the code?",
              style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
            ),
            GestureDetector(
              onTap: _remainingSeconds > 0 || _isSendingCode
                  ? null
                  : () => _sendCode(isResend: true),
              child: Text(
                _remainingSeconds > 0
                    ? "Resend code ($formattedTime)"
                    : "Resend code",
                style: TextStyle(
                  fontSize: 14,
                  color: _remainingSeconds > 0
                      ? const Color(0xFF999999)
                      : const Color(0xFF006837),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F8F5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF00A86B), width: 1),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFF00A86B),
                size: 20,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "The code will expire in 5 minutes",
                  style: TextStyle(color: Color(0xFF333333), fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              final code = _verificationCodeControllers
                  .map((c) => c.text)
                  .join();
              if (code.length < 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter the 4-digit code.'),
                  ),
                );
                return;
              }
              setState(() {
                _currentStep = 2;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006837),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text(
              'Continue',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordResetScreen() {
    final password = _newPasswordController.text;
    final isPasswordValid =
        password.length >= 8 && password.contains(RegExp(r'[0-9]'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _stepIndicator(1, "Email"),
              _stepIndicator(2, "Verify"),
              _stepIndicator(3, "Password"),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          "Create new password",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Your new password must be different from previous passwords",
          style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
        ),
        const SizedBox(height: 28),
        const Text(
          "New password",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _newPasswordController,
          obscureText: _obscureNewPassword,
          onChanged: (value) {
            setState(() {});
          },
          decoration: InputDecoration(
            hintText: "Enter new password",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF006837)),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF999999),
              ),
              onPressed: () {
                setState(() {
                  _obscureNewPassword = !_obscureNewPassword;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildPasswordValidationRules(password),
        const SizedBox(height: 28),
        const Text(
          "Confirm new password",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          onChanged: (value) {
            setState(() {});
          },
          decoration: InputDecoration(
            hintText: "Confirm new password",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF006837)),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: const Color(0xFF999999),
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: LoadingButton(
            isLoading: _isResetting,
            onPressed:
                isPasswordValid &&
                    _confirmPasswordController.text ==
                        _newPasswordController.text
                ? _resetPassword
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006837),
              disabledBackgroundColor: const Color(0xFFCCCCCC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text(
              'Reset Password',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordValidationRules(String password) {
    final hasMinLength = password.length >= 8;
    final hasNumber = password.contains(RegExp(r'[0-9]'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildValidationRule("At least 8 characters", hasMinLength),
        const SizedBox(height: 8),
        _buildValidationRule("Include a number", hasNumber),
      ],
    );
  }

  Widget _buildValidationRule(String rule, bool isValid) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isValid
                  ? const Color(0xFF006837)
                  : const Color(0xFFDDDDDD),
              width: 2,
            ),
          ),
          child: isValid
              ? const Icon(Icons.check, size: 12, color: Color(0xFF006837))
              : null,
        ),
        const SizedBox(width: 12),
        Text(
          rule,
          style: TextStyle(
            fontSize: 14,
            color: isValid ? const Color(0xFF006837) : const Color(0xFF666666),
            fontWeight: isValid ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordResetSuccessScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFF0F7F3),
          ),
          child: Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF006837),
              ),
              child: const Center(
                child: Icon(Icons.check, color: Colors.white, size: 48),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          "Password Reset",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF006837),
          ),
        ),
        const Text(
          "Successful!",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF006837),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "Your password has been updated\nsuccessfully. You can now use your\nnew password to log in.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Color(0xFF666666), height: 1.5),
        ),
        const SizedBox(height: 50),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006837),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text(
              'Go to Sign In',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
