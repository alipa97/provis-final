import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class VerificationCodePage extends StatefulWidget {
  const VerificationCodePage({Key? key}) : super(key: key);

  @override
  State<VerificationCodePage> createState() => _VerificationCodePageState();
}

class _VerificationCodePageState extends State<VerificationCodePage> {
  // Pre-filled verification code for demonstration
  final List<String> _verificationCode = ['2', '7', '3', '9', '1', '6'];
  int _resendSeconds = 49;
  late Timer _timer;
  bool _isCodeComplete = true; // Set to true since code is pre-filled
  int _currentIndex = 5; // Last digit is selected

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendSeconds > 0) {
          _resendSeconds--;
        } else {
          _timer.cancel();
        }
      });
    });
  }

  void _resendCode() {
    if (_resendSeconds == 0) {
      setState(() {
        _resendSeconds = 60;
        // Clear the code
        for (int i = 0; i < _verificationCode.length; i++) {
          _verificationCode[i] = '';
        }
        _currentIndex = 0;
        _isCodeComplete = false;
      });
      _startResendTimer();
      // Add logic to resend verification code
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification code resent!'),
          backgroundColor: Color(0xFF0E9B8A),
        ),
      );
    }
  }

  void _onKeyPressed(String value) {
    if (value == 'backspace') {
      if (_currentIndex > 0) {
        setState(() {
          _currentIndex--;
          _verificationCode[_currentIndex] = '';
          _isCodeComplete = false;
        });
      }
    } else {
      if (_currentIndex < _verificationCode.length) {
        setState(() {
          _verificationCode[_currentIndex] = value;
          if (_currentIndex < _verificationCode.length - 1) {
            _currentIndex++;
          }
          
          // Check if all digits are filled
          _isCodeComplete = !_verificationCode.contains('');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Center(
                child: Text(
                  'Forgot Your Password',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0E9B8A),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'You\'ve Got Mail',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'We will send you the verification code to your email address, check your email and put the code right below.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  6,
                  (index) => _buildCodeDigit(index),
                ),
              ),
              const SizedBox(height: 40),
              Center(
                child: GestureDetector(
                  onTap: _resendCode,
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                      children: [
                        const TextSpan(text: 'Didn\'t receive the mail?\n'),
                        const TextSpan(text: 'You can resend it in '),
                        TextSpan(
                          text: '$_resendSeconds',
                          style: const TextStyle(
                            color: Color(0xFF0E9B8A),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(text: ' sec'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _isCodeComplete
                      ? () {
                          // Handle verification logic
                          print('Verifying code: ${_verificationCode.join()}');
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB2D8D8),
                    foregroundColor: const Color(0xFF0E9B8A),
                    disabledBackgroundColor: const Color(0xFFB2D8D8).withOpacity(0.7),
                    disabledForegroundColor: const Color(0xFF0E9B8A).withOpacity(0.5),
                    minimumSize: const Size(300, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              _buildNumericKeypad(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCodeDigit(int index) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFF0E9B8A),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Center(
        child: Text(
          _verificationCode[index],
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildNumericKeypad() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKeypadButton('1'),
            _buildKeypadButton('2'),
            _buildKeypadButton('3'),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKeypadButton('4'),
            _buildKeypadButton('5'),
            _buildKeypadButton('6'),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKeypadButton('7'),
            _buildKeypadButton('8'),
            _buildKeypadButton('9'),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKeypadButton('*'),
            _buildKeypadButton('0'),
            _buildKeypadButton('backspace', icon: Icons.backspace_outlined),
          ],
        ),
      ],
    );
  }

  Widget _buildKeypadButton(String value, {IconData? icon}) {
    return InkWell(
      onTap: () => _onKeyPressed(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 100,
        height: 50,
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFFB2D8D8),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: icon != null
              ? Icon(
                  icon,
                  color: Colors.black87,
                  size: 24,
                )
              : Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
        ),
      ),
  );
  }
}