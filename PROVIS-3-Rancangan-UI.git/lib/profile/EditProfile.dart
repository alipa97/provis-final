import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ← TAMBAH INI
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../auth/Login.dart'; // ← TAMBAH INI
import 'dart:convert';
import 'dart:io';

class EditProfile extends StatefulWidget {
  const EditProfile({Key? key}) : super(key: key);

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _presentationController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();

  // ← TAMBAH TOKEN MANAGEMENT
  String? authToken;

  // State management
  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;
  Map<String, dynamic> userProfile = {};
  File? _selectedImage;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchProfile(); // ← GANTI METHOD
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _presentationController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  // ← TAMBAH METHOD LOAD TOKEN
  Future<void> _loadTokenAndFetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      authToken = prefs.getString('auth_token');
    });
    
    if (authToken != null) {
      await _fetchUserProfile();
    } else {
      // Redirect ke login
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
        (route) => false,
      );
    }
  }

  // ← UPDATE METHOD INI untuk Node.js backend
  Future<void> _fetchUserProfile() async {
    if (authToken == null) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // UPDATE: Sesuai dengan Node.js endpoint
      final response = await http.get(
        Uri.parse('$baseUrl/profile'), // Node.js: /api/profile
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken', // ← GUNAKAN TOKEN DARI SHARED PREFERENCES
        },
      );

      print('Profile Status: ${response.statusCode}');
      print('Profile Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // UPDATE: Sesuai dengan Node.js response structure
        if (data['status'] == 'success') {
          final userData = data['data']['user'];
          
          setState(() {
            userProfile = userData;
            
            // Populate form fields with current data
            _nameController.text = userData['name'] ?? '';
            _usernameController.text = userData['username'] ?? '';
            _presentationController.text = userData['presentation'] ?? '';
            _linkController.text = userData['add_link'] ?? '';
            
            // UPDATE: Set current profile image sesuai Node.js structure
            _currentImageUrl = userData['foto'] != null 
                ? (userData['foto'].startsWith('http') 
                    ? userData['foto'] 
                    : '$baseUrl${userData['foto']}') // Node.js mengembalikan path lengkap
                : null;
          });
          
          print('Profile loaded: ${userData['name']}');
        } else {
          throw Exception(data['message'] ?? 'Failed to load profile');
        }
      } else if (response.statusCode == 401) {
        // Token expired, redirect ke login
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Login()),
          (route) => false,
        );
        return;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to load profile');
      }
    } catch (e) {
      print('Error fetching profile: $e');
      setState(() {
        errorMessage = 'Failed to load profile: $e';
        // Fallback data untuk testing
        _nameController.text = 'Alifa Bee';
        _usernameController.text = 'alifabee';
        _presentationController.text = 'My passion is cooking and sharing new recipes with the world.';
        _linkController.text = '';
        _currentImageUrl = 'https://images.unsplash.com/photo-1494790108377-be9c29b29330';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Pick image from gallery
  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ← UPDATE METHOD INI untuk Node.js backend
  Future<void> _saveProfile() async {
    if (authToken == null) return;

    // Validation
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_usernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // URL validation untuk add_link jika diisi
    if (_linkController.text.trim().isNotEmpty) {
      final urlPattern = r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$';
      final regex = RegExp(urlPattern);
      if (!regex.hasMatch(_linkController.text.trim())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid URL'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      isSaving = true;
      errorMessage = null;
    });

    try {
      // UPDATE: Prepare multipart request untuk Node.js backend
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/profile'), // Node.js: /api/profile
      );

      // Add headers - sesuai dengan Node.js auth middleware
      request.headers.addAll({
        'Authorization': 'Bearer $authToken',
        'Accept': 'application/json',
      });

      // Add form fields - sesuai dengan Node.js controller field names
      request.fields['name'] = _nameController.text.trim();
      request.fields['username'] = _usernameController.text.trim();
      request.fields['presentation'] = _presentationController.text.trim();
      request.fields['add_link'] = _linkController.text.trim();

      // Add image file if selected - sesuai dengan Node.js multer field name
      if (_selectedImage != null) {
        var imageFile = await http.MultipartFile.fromPath(
          'foto', // ← FIELD NAME SESUAI DENGAN NODE.JS MULTER CONFIG
          _selectedImage!.path,
        );
        request.files.add(imageFile);
      }

      print('Sending update request to: $baseUrl/profile');
      print('Request fields: ${request.fields}');
      print('Request files: ${_selectedImage != null ? 'foto included' : 'no files'}');
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('Update Status: ${response.statusCode}');
      print('Update Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // UPDATE: Sesuai dengan Node.js response structure
        if (data['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Profile updated successfully!'),
              backgroundColor: const Color(0xFF2A9D8F),
            ),
          );

          // Navigate back to profile dengan success indicator
          Navigator.pop(context, true); // Pass true to indicate successful update
        } else {
          throw Exception(data['message'] ?? 'Failed to update profile');
        }
        
      } else if (response.statusCode == 422) {
        // UPDATE: Handle validation errors dari Node.js
        final data = json.decode(response.body);
        
        String errorText = data['message'] ?? 'Validation errors occurred';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorText),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      } else if (response.statusCode == 401) {
        // Token expired, redirect ke login
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Login()),
          (route) => false,
        );
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      print('Error saving profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2A9D8F)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Color(0xFF2A9D8F),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading 
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2A9D8F)),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    
                    // Profile Picture
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF2A9D8F),
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 48,
                                backgroundImage: _selectedImage != null
                                    ? FileImage(_selectedImage!)
                                    : (_currentImageUrl != null
                                        ? NetworkImage(_currentImageUrl!)
                                        : const NetworkImage(
                                            'https://images.unsplash.com/photo-1494790108377-be9c29b29330'
                                          )) as ImageProvider,
                                onBackgroundImageError: (exception, stackTrace) {
                                  print('Error loading image: $exception');
                                },
                                child: _selectedImage == null && _currentImageUrl == null
                                    ? const Icon(Icons.person, size: 50, color: Colors.grey)
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _pickImage,
                            child: const Text(
                              'Edit Photo',
                              style: TextStyle(
                                color: Color(0xFF2A9D8F),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // Error message
                    if (errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Name Field
                    _buildInputField(
                      label: 'Name',
                      controller: _nameController,
                      isRequired: true,
                      hint: 'Enter your full name',
                    ),
                    const SizedBox(height: 20),
                    
                    // Username Field
                    _buildInputField(
                      label: 'Username',
                      controller: _usernameController,
                      isRequired: true,
                      hint: 'Enter your username (letters, numbers, underscore only)',
                    ),
                    const SizedBox(height: 20),
                    
                    // Presentation Field
                    _buildInputField(
                      label: 'Bio/Presentation',
                      controller: _presentationController,
                      maxLines: 3,
                      hint: 'Tell us about yourself...',
                    ),
                    const SizedBox(height: 20),
                    
                    // Add Link Field
                    _buildInputField(
                      label: 'Website/Social Link',
                      controller: _linkController,
                      hint: 'https://example.com',
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 40),
                    
                    // Save Button
                    SizedBox(
                      width: 150,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2A9D8F),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 2,
                        ),
                        child: isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Save',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    String? hint,
    bool isRequired = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2A9D8F),
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFB2DFDB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: const BorderSide(
                color: Color(0xFF2A9D8F),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: maxLines > 1 ? 15 : 12,
            ),
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          // ← TAMBAH INPUT VALIDATION FEEDBACK
          onChanged: (value) {
            if (isRequired && value.trim().isEmpty) {
              // Could add real-time validation here
            }
            
            // Username validation
            if (label == 'Username' && value.isNotEmpty) {
              final usernamePattern = r'^[a-zA-Z0-9_]+$';
              final regex = RegExp(usernamePattern);
              if (!regex.hasMatch(value)) {
                // Could show validation message
              }
            }
          },
        ),
      ],
    );
  }
}