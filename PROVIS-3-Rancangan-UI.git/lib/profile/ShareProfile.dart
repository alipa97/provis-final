import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ← TAMBAH INI
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../auth/Login.dart'; // ← TAMBAH INI
import 'dart:convert';

class ShareProfile extends StatefulWidget { // ← GANTI KE STATEFUL
  const ShareProfile({Key? key}) : super(key: key);

  @override
  State<ShareProfile> createState() => _ShareProfileState();
}

class _ShareProfileState extends State<ShareProfile> {
  // ← TAMBAH STATE MANAGEMENT
  String? authToken;
  bool isLoading = true;
  String? errorMessage;
  
  // User data dari API
  String username = "@username";
  String name = "Username";
  String profileUrl = "https://example.com/profile/username";
  String? profileImageUrl;
  Map<String, dynamic> userProfile = {};

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchProfile(); // ← TAMBAH FETCH PROFILE
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

  // ← TAMBAH METHOD FETCH PROFILE
  Future<void> _fetchUserProfile() async {
    if (authToken == null) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // UPDATE: Ambil data user dari Node.js endpoint
      final response = await http.get(
        Uri.parse('$baseUrl/profile'), // Node.js: /api/profile
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      print('Profile Status: ${response.statusCode}');
      print('Profile Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // UPDATE: Parse response sesuai Node.js structure
        if (data['status'] == 'success') {
          final userData = data['data']['user'];
          
          setState(() {
            userProfile = userData;
            name = userData['name'] ?? 'Unknown User';
            username = '@${userData['username'] ?? userData['name']}';
            
            // UPDATE: Generate profile URL berdasarkan username
            profileUrl = '$baseUrl/profile/${userData['username'] ?? userData['id']}';
            
            // UPDATE: Set profile image
            profileImageUrl = userData['foto'] != null 
                ? (userData['foto'].startsWith('http') 
                    ? userData['foto'] 
                    : '$baseUrl${userData['foto']}')
                : null;
          });
          
          print('Profile loaded for sharing: $name ($username)');
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
        // Fallback data
        name = 'Alifa Bee';
        username = '@alifabee';
        profileUrl = '$baseUrl/profile/alifabee';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00897B), // Teal background color
      appBar: AppBar(
        backgroundColor: const Color(0xFF00897B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Share Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading 
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : errorMessage != null
              ? _buildErrorState()
              : _buildShareContent(),
    );
  }

  // ← TAMBAH ERROR STATE
  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load profile',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTokenAndFetchProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00897B),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ← UPDATE CONTENT DENGAN DATA DINAMIS
  Widget _buildShareContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // QR Code Card
          Container(
            width: 300,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                // Profile Image (jika ada)
                if (profileImageUrl != null) ...[
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(profileImageUrl!),
                    onBackgroundImageError: (_, __) {},
                    child: profileImageUrl == null 
                        ? const Icon(Icons.person, size: 30, color: Colors.grey) 
                        : null,
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Name
                Text(
                  name, // ← DINAMIS DARI API
                  style: const TextStyle(
                    color: Color(0xFF4DB6AC),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                
                // Username
                Text(
                  username, // ← DINAMIS DARI API
                  style: const TextStyle(
                    color: Color(0xFF4DB6AC),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Custom QR Code (simplified representation)
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFF4DB6AC), width: 2),
                  ),
                  child: Stack(
                    children: [
                      CustomPaint(
                        painter: SimplifiedQRPainter(color: const Color(0xFF4DB6AC)),
                        size: const Size(200, 200),
                      ),
                      // Add a small profile indicator in center
                      Center(
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF4DB6AC), width: 2),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Color(0xFF4DB6AC),
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Profile URL (small text)
                Text(
                  profileUrl, // ← DINAMIS DARI API
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      context, 
                      "Share", 
                      Icons.share,
                      () => _shareProfile(context)
                    ),
                    _buildActionButton(
                      context, 
                      "Copy Link", 
                      Icons.link,
                      () => _copyLink(context)
                    ),
                    _buildActionButton(
                      context, 
                      "Download", 
                      Icons.download,
                      () => _downloadQR(context)
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Additional sharing options
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Text(
                  'Share your profile with friends!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Scan QR code or use the link above',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ← UPDATE ACTION BUTTON DENGAN ICON
  Widget _buildActionButton(BuildContext context, String label, IconData icon, VoidCallback onPressed) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFB2DFDB),
            foregroundColor: const Color(0xFF00897B),
            padding: const EdgeInsets.all(12),
            shape: const CircleBorder(),
            elevation: 2,
          ),
          child: Icon(icon, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF4DB6AC),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ← UPDATE SHARE METHOD
  void _shareProfile(BuildContext context) {
    // Generate share text dengan data user
    final shareText = '''
Check out ${name}'s profile on our app!

Username: $username
Profile: $profileUrl

Download the app to see more recipes and connect with $name!
''';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Share ${name}\'s profile:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                shareText,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: shareText));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Share text copied to clipboard'),
                  backgroundColor: Color(0xFF00897B),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00897B),
            ),
            child: const Text(
              'Copy Text',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ← UPDATE COPY LINK METHOD
  void _copyLink(BuildContext context) {
    Clipboard.setData(ClipboardData(text: profileUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${name}\'s profile link copied to clipboard'),
        backgroundColor: const Color(0xFF00897B),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ← UPDATE DOWNLOAD METHOD
  void _downloadQR(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download QR Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Save ${name}\'s profile QR code'),
            const SizedBox(height: 16),
            const Text(
              'QR code download feature will be available in a future update.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// ← ENHANCED QR PAINTER
class SimplifiedQRPainter extends CustomPainter {
  final Color color;
  
  SimplifiedQRPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    // Draw a simplified QR code pattern
    final double blockSize = size.width / 12;
    
    // Corner squares (finder patterns)
    _drawFinderPattern(canvas, paint, blockSize, blockSize, blockSize);
    _drawFinderPattern(canvas, paint, blockSize * 8, blockSize, blockSize);
    _drawFinderPattern(canvas, paint, blockSize, blockSize * 8, blockSize);
    
    // Timing patterns
    for (int i = 0; i < 12; i += 2) {
      canvas.drawRect(Rect.fromLTWH(i * blockSize, blockSize * 6, blockSize, blockSize), paint);
      canvas.drawRect(Rect.fromLTWH(blockSize * 6, i * blockSize, blockSize, blockSize), paint);
    }
    
    // Data modules (simplified pattern)
    final dataPositions = [
      [2, 2], [3, 3], [9, 2], [10, 3], [2, 9], [3, 10],
      [5, 4], [4, 5], [7, 4], [8, 5], [5, 7], [7, 8],
      [9, 9], [10, 10], [4, 9], [5, 10], [9, 4], [10, 5],
    ];
    
    for (final pos in dataPositions) {
      canvas.drawRect(
        Rect.fromLTWH(pos[0] * blockSize, pos[1] * blockSize, blockSize, blockSize), 
        paint
      );
    }
  }
  
  void _drawFinderPattern(Canvas canvas, Paint paint, double x, double y, double blockSize) {
    // Outer square
    canvas.drawRect(Rect.fromLTWH(x, y, blockSize * 3, blockSize * 3), paint);
    // Inner white square
    canvas.drawRect(
      Rect.fromLTWH(x + blockSize * 0.5, y + blockSize * 0.5, blockSize * 2, blockSize * 2), 
      Paint()..color = Colors.white..style = PaintingStyle.fill
    );
    // Center square
    canvas.drawRect(
      Rect.fromLTWH(x + blockSize, y + blockSize, blockSize, blockSize), 
      paint
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}