import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ← TAMBAH INI
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../auth/Login.dart'; // ← TAMBAH INI


class EditRecipePage extends StatefulWidget {
  const EditRecipePage({Key? key}) : super(key: key);

  @override
  State<EditRecipePage> createState() => _EditRecipePageState();
}

class _EditRecipePageState extends State<EditRecipePage> {
  bool _isLoading = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  String? authToken; 

  // Controllers sesuai dengan backend API
  final TextEditingController namaController = TextEditingController();
  final TextEditingController detailController = TextEditingController();
  final TextEditingController durasiController = TextEditingController();
  final TextEditingController estimasiWaktuController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadToken(); // ← LOAD TOKEN DULU
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      authToken = prefs.getString('auth_token');
    });
    
    if (authToken != null) {
      await fetchEditRecipePage();
    } else {
      // Redirect ke login
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
        (route) => false,
      );
    }
  }
  
  // Dropdown untuk kategori
  String? selectedKategori;
  final List<Map<String, String>> kategoriOptions = [
    {'value': 'makanan_utama', 'display': 'Makanan Utama'},
    {'value': 'makanan_ringan', 'display': 'Makanan Ringan'},
    {'value': 'minuman', 'display': 'Minuman'},
    {'value': 'dessert', 'display': 'Dessert'},
    {'value': 'sarapan', 'display': 'Sarapan'},
  ];

  // Dropdown untuk jenis hidangan
  String? selectedJenisHidangan;
  final List<Map<String, String>> jenisHidanganOptions = [
    {'value': 'nusantara', 'display': 'Nusantara'},
    {'value': 'asia', 'display': 'Asia'},
    {'value': 'barat', 'display': 'Barat'},
    {'value': 'timur_tengah', 'display': 'Timur Tengah'},
    {'value': 'vegetarian', 'display': 'Vegetarian'},
    {'value': 'vegan', 'display': 'Vegan'},
  ];

  // Dropdown untuk tingkat kesulitan
  String? selectedTingkatKesulitan;
  final List<Map<String, String>> tingkatKesulitanOptions = [
    {'value': 'mudah', 'display': 'Mudah'},
    {'value': 'sedang', 'display': 'Sedang'},
    {'value': 'sulit', 'display': 'Sulit'},
  ];

  // Dropdown untuk waktu estimasi
  String? selectedWaktuEstimasi;
  final List<Map<String, String>> waktuEstimasiOptions = [
    {'value': '<15', 'display': '<15'},
    {'value': '<30', 'display': '<30'},
    {'value': '<60', 'display': '<60'},
  ];

  // Function untuk memilih gambar
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorDialog('Gagal memilih gambar: $e');
    }
  }

  Future<void> fetchEditRecipePage() async {
    // Validasi input
    if (!_validateInputs()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/recipes'),
      );

      // Add headers
      request.headers['Content-Type'] = 'multipart/form-data';
      // TODO: Add authorization token if needed
      // request.headers['Authorization'] = 'Bearer $token';

      // Add fields
      request.fields['nama'] = namaController.text.trim();
      request.fields['detail'] = detailController.text.trim();
      request.fields['durasi'] = durasiController.text.trim();
      request.fields['kategori'] = selectedKategori!;
      request.fields['jenis_hidangan'] = selectedJenisHidangan!;
      request.fields['estimasi_waktu'] = estimasiWaktuController.text.trim();
      request.fields['tingkat_kesulitan'] = selectedTingkatKesulitan!;
      request.fields['estimasi_waktu'] = selectedWaktuEstimasi!;

      // Add image file if selected
      if (_selectedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'foto',
            _selectedImage!.path,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 201) {
        // Success response
        final data = jsonDecode(response.body);
        print('Add Recipe Success: $data');
        
        if (mounted) {
          _showSuccessDialog(data['message'] ?? 'Resep berhasil ditambahkan');
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
          errorMessage = errorData['message'];
        } else {
          errorMessage = 'Validasi gagal';
        }
        
        _showErrorDialog(errorMessage);
      } else {
        // Other error responses
        final errorData = jsonDecode(response.body);
        String errorMessage = errorData['message'] ?? 'Gagal menambahkan resep';
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
    if (namaController.text.trim().isEmpty) {
      _showErrorDialog('Nama resep tidak boleh kosong');
      return false;
    }

    if (detailController.text.trim().isEmpty) {
      _showErrorDialog('Detail resep tidak boleh kosong');
      return false;
    }

    if (durasiController.text.trim().isEmpty) {
      _showErrorDialog('Durasi tidak boleh kosong');
      return false;
    }

    if (selectedKategori == null) {
      _showErrorDialog('Kategori harus dipilih');
      return false;
    }

    if (selectedJenisHidangan == null) {
      _showErrorDialog('Jenis hidangan harus dipilih');
      return false;
    }

    if (estimasiWaktuController.text.trim().isEmpty) {
      _showErrorDialog('Estimasi waktu tidak boleh kosong');
      return false;
    }

    if (selectedTingkatKesulitan == null) {
      _showErrorDialog('Tingkat kesulitan harus dipilih');
      return false;
    }

    if (selectedWaktuEstimasi == null) {
      _showErrorDialog('Estimasi waktu harus dipilih');
      return false;
    }

    return true;
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
                // Navigate back to previous screen
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0E9B8A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Tambah Resep',
          style: TextStyle(
            color: Color(0xFF0E9B8A),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image picker section
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: const Color(0xFFB2D8D8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF0E9B8A),
                        style: BorderStyle.solid,
                        width: 2,
                      ),
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                size: 50,
                                color: Color(0xFF0E9B8A),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Tambah Foto Resep',
                                style: TextStyle(
                                  color: Color(0xFF0E9B8A),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildInputField(
                  label: 'Nama Resep',
                  hintText: 'Masukkan nama resep',
                  keyboardType: TextInputType.text,
                  controller: namaController,
                ),
                const SizedBox(height: 20),
                _buildInputField(
                  label: 'Detail Resep',
                  hintText: 'Masukkan detail resep dan cara membuat',
                  keyboardType: TextInputType.multiline,
                  controller: detailController,
                  maxLines: 5,
                ),
                const SizedBox(height: 20),
                _buildInputField(
                  label: 'Durasi',
                  hintText: 'Contoh: 30 menit',
                  keyboardType: TextInputType.text,
                  controller: durasiController,
                ),
                const SizedBox(height: 20),
                _buildDropdown(
                  label: 'Kategori',
                  value: selectedKategori,
                  items: kategoriOptions,
                  hint: 'Pilih kategori',
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedKategori = newValue;
                    });
                  },
                ),
                const SizedBox(height: 20),
                _buildDropdown(
                  label: 'Jenis Hidangan',
                  value: selectedJenisHidangan,
                  items: jenisHidanganOptions,
                  hint: 'Pilih jenis hidangan',
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedJenisHidangan = newValue;
                    });
                  },
                ),
                const SizedBox(height: 20),
                _buildDropdown(
                  label: 'Estimasi Waktu',
                  value: selectedWaktuEstimasi,
                  items: waktuEstimasiOptions,
                  hint: 'Pilih estimasi waktu',
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedWaktuEstimasi = newValue;
                    });
                  },
                ),
                const SizedBox(height: 20),
                _buildDropdown(
                  label: 'Tingkat Kesulitan',
                  value: selectedTingkatKesulitan,
                  items: tingkatKesulitanOptions,
                  hint: 'Pilih tingkat kesulitan',
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedTingkatKesulitan = newValue;
                    });
                  },
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isLoading ? null : fetchEditRecipePage,
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
                        'Tambah Resep',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                ),
                const SizedBox(height: 20),
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
    int maxLines = 1,
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
          maxLines: maxLines,
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
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<Map<String, String>> items,
    required String hint,
    required ValueChanged<String?> onChanged,
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFB2D8D8),
            borderRadius: BorderRadius.circular(30),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(hint),
              isExpanded: true,
              items: items.map((Map<String, String> option) {
                return DropdownMenuItem<String>(
                  value: option['value'],
                  child: Text(option['display']!),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}