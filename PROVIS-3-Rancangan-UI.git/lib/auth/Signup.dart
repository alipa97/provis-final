import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'dart:convert';
import 'Login.dart';
import '../home/HomePage.dart';

class SignUp extends StatefulWidget {
  const SignUp({Key? key}) : super(key: key);

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;

  // Controllers sesuai dengan backend API
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController noHpController = TextEditingController();
  final TextEditingController tanggalLahirController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  
  // Dropdown untuk gender - sesuai backend: male/female
  String? selectedGender;
  final List<Map<String, String>> genderOptions = [
    {'value': 'male', 'display': 'Laki-laki'},
    {'value': 'female', 'display': 'Perempuan'},
  ];

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    usernameController.dispose();
    noHpController.dispose();
    tanggalLahirController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> fetchSignUp() async {
    // Validasi input
    if (!_validateInputs()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': nameController.text.trim(),
          'email': emailController.text.trim().toLowerCase(),
          'username': usernameController.text.trim(),
          'no_hp': noHpController.text.trim(),
          'tanggal_lahir': tanggalLahirController.text.trim(),
          'password': passwordController.text,
          'gender': selectedGender, // Kirim 'male' atau 'female'
        }),
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 201) {
        // Success response
        final data = jsonDecode(response.body);
        print('SignUp Success: $data');
        
        // Simpan token jika diperlukan
        // SharedPreferences prefs = await SharedPreferences.getInstance();
        // if (data['data']['token'] != null) {
        //   await prefs.setString('token', data['data']['token']);
        // }
        // await prefs.setString('user_id', data['data']['user']['id'].toString());
        
        if (mounted) {
          _showSuccessDialog(data['message'] ?? 'Registrasi berhasil');
        }
      } else if (response.statusCode == 422) {
        // Validation error
        final errorData = jsonDecode(response.body);
        
        String errorMessage = '';
        if (errorData['errors'] != null && errorData['errors'].isNotEmpty) {
          // Handle validation errors array
          List<dynamic> errors = errorData['errors'];
          errorMessage = errors.map((error) => error['msg'] ?? error.toString()).join(', ');
        } else if (errorData['message'] != null) {
          // Handle single error message (email/no_hp sudah terdaftar)
          errorMessage = errorData['message'];
        } else {
          errorMessage = 'Validasi gagal';
        }
        
        _showErrorDialog(errorMessage);
      } else {
        // Other error responses
        final errorData = jsonDecode(response.body);
        String errorMessage = errorData['message'] ?? 'Sign up gagal';
        _showErrorDialog(errorMessage);
      }
    } catch (e) {
      print('Error Details: $e');
      _showErrorDialog('Terjadi kesalahan koneksi. Silakan coba lagi.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _validateInputs() {
    if (nameController.text.trim().isEmpty) {
      _showErrorDialog('Nama tidak boleh kosong');
      return false;
    }

    if (emailController.text.trim().isEmpty) {
      _showErrorDialog('Email tidak boleh kosong');
      return false;
    }

    if (!_isValidEmail(emailController.text.trim())) {
      _showErrorDialog('Format email tidak valid');
      return false;
    }

    if (usernameController.text.trim().isEmpty) {
      _showErrorDialog('Username tidak boleh kosong');
      return false;
    }

    if (noHpController.text.trim().isEmpty) {
      _showErrorDialog('Nomor HP tidak boleh kosong');
      return false;
    }

    if (tanggalLahirController.text.trim().isEmpty) {
      _showErrorDialog('Tanggal lahir tidak boleh kosong');
      return false;
    }

    if (selectedGender == null) {
      _showErrorDialog('Jenis kelamin harus dipilih');
      return false;
    }

    if (passwordController.text.isEmpty) {
      _showErrorDialog('Password tidak boleh kosong');
      return false;
    }

    if (passwordController.text.length < 6) {
      _showErrorDialog('Password minimal 6 karakter');
      return false;
    }

    if (passwordController.text != confirmPasswordController.text) {
      _showErrorDialog('Password dan konfirmasi password tidak sama');
      return false;
    }

    return true;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Berhasil'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate ke homepage setelah signup berhasil
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Function untuk date picker
  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 tahun yang lalu
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    
    if (pickedDate != null) {
      setState(() {
        tanggalLahirController.text = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Sign Up',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0E9B8A),
                  ),
                ),
                const SizedBox(height: 40),
                _buildInputField(
                  label: 'Name',
                  hintText: 'Enter your full name',
                  keyboardType: TextInputType.name,
                  controller: nameController,
                ),
                const SizedBox(height: 20),
                _buildInputField(
                  label: 'Email',
                  hintText: 'example@example.com',
                  keyboardType: TextInputType.emailAddress,
                  controller: emailController,
                ),
                const SizedBox(height: 20),
                _buildInputField(
                  label: 'Username',
                  hintText: 'Enter username',
                  keyboardType: TextInputType.text,
                  controller: usernameController,
                ),
                const SizedBox(height: 20),
                _buildInputField(
                  label: 'No HP',
                  hintText: '+62 812 3456 789',
                  keyboardType: TextInputType.phone,
                  controller: noHpController,
                ),
                const SizedBox(height: 20),
                _buildInputField(
                  label: 'Tanggal Lahir',
                  hintText: 'YYYY-MM-DD',
                  keyboardType: TextInputType.datetime,
                  controller: tanggalLahirController,
                  readOnly: true,
                  onTap: _selectDate,
                ),
                const SizedBox(height: 20),
                _buildGenderDropdown(),
                const SizedBox(height: 20),
                _buildPasswordField(
                  label: 'Password',
                  isPassword: true,
                  showPassword: _showPassword,
                  controller: passwordController,
                  onToggleVisibility: () {
                    setState(() {
                      _showPassword = !_showPassword;
                    });
                  },
                ),
                const SizedBox(height: 20),
                _buildPasswordField(
                  label: 'Confirm Password',
                  isPassword: true,
                  showPassword: _showConfirmPassword,
                  controller: confirmPasswordController,
                  onToggleVisibility: () {
                    setState(() {
                      _showConfirmPassword = !_showConfirmPassword;
                    });
                  },
                ),
                const SizedBox(height: 30),
                const Text(
                  'By continuing, you agree to Terms of Use and Privacy Policy.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : fetchSignUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0E9B8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isLoading 
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const Login()),
                        );
                      },
                      child: const Text(
                        'Log in',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.pink,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hintText,
    required TextInputType keyboardType,
    required TextEditingController controller,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: const Color(0xFFB2D8D8),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(
                color: Color(0xFF0E9B8A),
                width: 2,
              ),
            ),
            suffixIcon: readOnly ? const Icon(Icons.calendar_today, color: Colors.grey) : null,
          ),
        ),
      ],
    );
  }

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFB2D8D8),
            borderRadius: BorderRadius.circular(30),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedGender,
              hint: const Text('Pilih jenis kelamin'),
              isExpanded: true,
              items: genderOptions.map((Map<String, String> option) {
                return DropdownMenuItem<String>(
                  value: option['value'],
                  child: Text(option['display']!),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedGender = newValue;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required bool isPassword,
    required bool showPassword,
    required TextEditingController controller,
    required VoidCallback onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: !showPassword,
          decoration: InputDecoration(
            hintText: '••••••••',
            filled: true,
            fillColor: const Color(0xFFB2D8D8),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(
                color: Color(0xFF0E9B8A),
                width: 2,
              ),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                showPassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: onToggleVisibility,
            ),
          ),
        ),
      ],
    );
  }
}