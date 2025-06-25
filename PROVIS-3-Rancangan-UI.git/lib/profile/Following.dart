import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ← TAMBAH INI
import '../Main.dart';
import '../navbar/custom_navbar.dart';
import '../community/community.dart';
import '../myresep/EditRecipe.dart';
import '../search/Search.dart';
import 'Followers.dart' show FollowersPage;
import '../home/HomePage.dart';
import '../auth/Login.dart'; // ← TAMBAH INI
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'dart:convert';

class FollowingPage extends StatefulWidget {
  const FollowingPage({Key? key}) : super(key: key);

  @override
  State<FollowingPage> createState() => _FollowingPageState();
}

class _FollowingPageState extends State<FollowingPage> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 3; // Set to profile tab

  // ← TAMBAH TOKEN MANAGEMENT
  String? authToken;
  
  // State management untuk Following dan Profile data
  List<Map<String, dynamic>> following = [];
  bool isLoadingFollowing = true;
  bool isLoadingProfile = true;
  String? followingErrorMessage;
  String? profileErrorMessage;
  
  // User profile data - akan diambil dari API
  String username = '@username';
  int followersCount = 0;
  int followingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetch(); // ← GANTI METHOD
  }

  // ← TAMBAH METHOD LOAD TOKEN
  Future<void> _loadTokenAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      authToken = prefs.getString('auth_token');
    });
    
    if (authToken != null) {
      await Future.wait([
        _fetchProfile(),
        _fetchFollowing(),
      ]);
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
  Future<void> _fetchProfile() async {
    if (authToken == null) return;

    setState(() {
      isLoadingProfile = true;
      profileErrorMessage = null;
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
          final stats = data['data']['stats'];
          
          setState(() {
            username = '@${userData['username'] ?? userData['name']}';
            followersCount = stats['total_followers'] ?? 0;
            followingCount = stats['total_following'] ?? 0;
          });
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
        profileErrorMessage = 'Failed to load profile: $e';
        // Fallback data untuk testing
        username = '@alifabee';
        followersCount = 3;
        followingCount = 2;
      });
    } finally {
      setState(() {
        isLoadingProfile = false;
      });
    }
  }

  // ← UPDATE METHOD INI untuk Node.js backend
  Future<void> _fetchFollowing() async {
    if (authToken == null) return;

    setState(() {
      isLoadingFollowing = true;
      followingErrorMessage = null;
    });

    try {
      // UPDATE: Sesuai dengan Node.js endpoint
      final response = await http.get(
        Uri.parse('$baseUrl/profile/following'), // Node.js: /api/profile/following
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken', // ← GUNAKAN TOKEN DARI SHARED PREFERENCES
        },
      );

      print('Following Status: ${response.statusCode}');
      print('Following Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // UPDATE: Sesuai dengan Node.js response structure
        if (data['status'] == 'success') {
          final followingData = data['data']['following'] ?? [];
          
          setState(() {
            following = followingData.map<Map<String, dynamic>>((user) {
              return {
                'id': user['id'],
                'username': '@${user['username'] ?? user['name']}',
                'name': user['name'],
                // UPDATE: Handle foto URL dari Node.js
                'image': user['foto'] != null 
                    ? (user['foto'].startsWith('http') 
                        ? user['foto'] 
                        : '$baseUrl${user['foto']}')
                    : 'https://images.unsplash.com/photo-1494790108377-be9c29b29330',
                'followed_at': user['followed_at'] ?? '',
                'notifications_enabled': user['notifications_enabled'] ?? true,
                'is_blocked': user['is_blocked'] ?? false,
              };
            }).toList();
            
            // Update following count dari API response
            final stats = data['data']['stats'];
            if (stats != null) {
              followingCount = stats['total_following'] ?? following.length;
              followersCount = stats['total_followers'] ?? followersCount;
            }
            
            print('Following loaded: ${following.length}');
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to load following');
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
        throw Exception(errorData['message'] ?? 'Failed to load following');
      }
    } catch (e) {
      print('Error fetching following: $e');
      setState(() {
        followingErrorMessage = 'Failed to load following: $e';
        // Fallback data untuk testing (berdasarkan seeder)
        following = [
          {
            'id': 2,
            'username': '@klarakeren',
            'name': 'Klara Oliviera',
            'image': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330',
            'followed_at': '2024-01-15T10:30:00Z',
            'notifications_enabled': true,
            'is_blocked': false,
          },
          {
            'id': 3,
            'username': '@notnaex',
            'name': 'Naeya Adeani',
            'image': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80',
            'followed_at': '2024-01-10T08:20:00Z',
            'notifications_enabled': true,
            'is_blocked': false,
          },
        ];
        followingCount = following.length;
      });
    } finally {
      setState(() {
        isLoadingFollowing = false;
      });
    }
  }

  // ← UPDATE METHOD INI untuk Node.js backend
  Future<void> _unfollowUser(int userId, String username) async {
    if (authToken == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Unfollow'),
          content: Text('Are you sure you want to unfollow $username?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                
                try {
                  // UPDATE: Sesuai dengan Node.js endpoint toggle-follow
                  final response = await http.post(
                    Uri.parse('$baseUrl/profile/toggle-follow/$userId'), // Node.js: /api/profile/toggle-follow/:userId
                    headers: {
                      'Content-Type': 'application/json',
                      'Authorization': 'Bearer $authToken',
                    },
                  );

                  print('Unfollow status: ${response.statusCode}');
                  print('Unfollow response: ${response.body}');

                  if (response.statusCode == 200) {
                    final data = json.decode(response.body);
                    
                    // UPDATE: Sesuai dengan Node.js response structure
                    if (data['status'] == 'success') {
                      final isFollowing = data['data']['following'] ?? false;
                      
                      if (!isFollowing) {
                        // Remove from local list jika berhasil unfollow
                        setState(() {
                          following.removeWhere((user) => user['id'] == userId);
                          followingCount = following.length;
                        });
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(data['message'] ?? 'Unfollowed $username'),
                            backgroundColor: const Color(0xFF2A9D8F),
                          ),
                        );
                      } else {
                        throw Exception('Failed to unfollow user');
                      }
                    } else {
                      throw Exception(data['message'] ?? 'Failed to unfollow user');
                    }
                  } else if (response.statusCode == 401) {
                    // Token expired
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const Login()),
                      (route) => false,
                    );
                  } else {
                    final errorData = json.decode(response.body);
                    throw Exception(errorData['message'] ?? 'Failed to unfollow user');
                  }
                } catch (e) {
                  print('Error unfollowing user: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error unfollowing user: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Unfollow', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // ← TAMBAH SEARCH FUNCTIONALITY
  Future<void> _searchFollowing(String query) async {
    if (authToken == null || query.isEmpty) {
      _fetchFollowing(); // Reset ke semua following
      return;
    }

    setState(() {
      isLoadingFollowing = true;
      followingErrorMessage = null;
    });

    try {
      // UPDATE: Gunakan search query parameter
      final response = await http.get(
        Uri.parse('$baseUrl/profile/following?search=$query'), // Node.js mendukung search query
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      print('Search following status: ${response.statusCode}');
      print('Search following response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'success') {
          final followingData = data['data']['following'] ?? [];
          
          setState(() {
            following = followingData.map<Map<String, dynamic>>((user) {
              return {
                'id': user['id'],
                'username': '@${user['username'] ?? user['name']}',
                'name': user['name'],
                'image': user['foto'] != null 
                    ? (user['foto'].startsWith('http') 
                        ? user['foto'] 
                        : '$baseUrl${user['foto']}')
                    : 'https://images.unsplash.com/photo-1494790108377-be9c29b29330',
                'followed_at': user['followed_at'] ?? '',
                'notifications_enabled': user['notifications_enabled'] ?? true,
                'is_blocked': user['is_blocked'] ?? false,
              };
            }).toList();
            
            print('Search results: ${following.length} following found');
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to search following');
        }
      } else {
        throw Exception('Failed to search following');
      }
    } catch (e) {
      print('Error searching following: $e');
      setState(() {
        followingErrorMessage = 'Failed to search following: $e';
        following = []; // Clear results on error
      });
    } finally {
      setState(() {
        isLoadingFollowing = false;
      });
    }
  }

  // ← TAMBAH TOGGLE NOTIFICATIONS (NOTE: Backend belum support, jadi hanya update local state)
  Future<void> _toggleNotifications(int userId, bool currentStatus) async {
    setState(() {
      final index = following.indexWhere((user) => user['id'] == userId);
      if (index != -1) {
        following[index]['notifications_enabled'] = !currentStatus;
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(currentStatus 
            ? 'Notifications turned off' 
            : 'Notifications turned on'),
        backgroundColor: const Color(0xFF2A9D8F),
      ),
    );
    
    // NOTE: Bisa tambahkan API call ke backend jika ada endpoint untuk notifications
    // final response = await http.post(
    //   Uri.parse('$baseUrl/profile/toggle-notifications/$userId'),
    //   headers: {
    //     'Content-Type': 'application/json',
    //     'Authorization': 'Bearer $authToken',
    //   },
    //   body: json.encode({'notifications_enabled': !currentStatus}),
    // );
  }

  // Refresh functions
  Future<void> _refreshAll() async {
    await Future.wait([
      _fetchProfile(),
      _fetchFollowing(),
    ]);
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Community()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const EditRecipePage()),
        );
        break;
      case 3:
        // Tetap di halaman profil
        break;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(context),
                _buildSearchBar(),
                Expanded(
                  child: _buildFollowingList(),
                ),
                const SizedBox(height: 80), // Space for navigation bar
              ],
            ),
            CustomNavbar(
              selectedIndex: _selectedIndex,
              onItemTapped: _onNavItemTapped,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2A9D8F)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                username, // Dynamic username dari API
                style: const TextStyle(
                  color: Color(0xFF2A9D8F),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Color(0xFF2A9D8F),
                          width: 2.0,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      // Dynamic count dari API
                      isLoadingFollowing 
                        ? 'Loading...' 
                        : '$followingCount Following',
                      style: const TextStyle(
                        color: Color(0xFF2A9D8F),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FollowersPage()),
                      );
                    },
                    child: Text(
                      // Dynamic count dari API
                      isLoadingProfile 
                        ? 'Loading...' 
                        : '$followersCount Followers',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF90D4CE),
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: 'Search',
          hintStyle: TextStyle(color: Colors.white70),
          border: InputBorder.none,
          contentPadding: EdgeInsets.only(bottom: 12),
        ),
        style: const TextStyle(
          color: Colors.white,
        ),
        onChanged: (value) {
          // ← UPDATE: Implement search functionality
          if (value.isEmpty) {
            _fetchFollowing(); // Reset jika search kosong
          } else {
            _searchFollowing(value); // Search dengan query
          }
        },
      ),
    );
  }

  Widget _buildFollowingList() {
    // Loading state
    if (isLoadingFollowing) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(
            color: Color(0xFF2A9D8F),
          ),
        ),
      );
    }
    
    // Error state dengan retry button
    if (followingErrorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                followingErrorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _refreshAll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A9D8F),
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
    
    // Empty state
    if (following.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                _searchController.text.isNotEmpty 
                    ? 'No following found for "${_searchController.text}"'
                    : 'No following found.',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    // Success state - tampilkan following dengan RefreshIndicator
    return RefreshIndicator(
      onRefresh: _refreshAll,
      color: const Color(0xFF2A9D8F),
      child: ListView.builder(
        itemCount: following.length,
        padding: const EdgeInsets.all(0),
        itemBuilder: (context, index) {
          final user = following[index];
          return _buildFollowingItem(user);
        },
      ),
    );
  }

  Widget _buildFollowingItem(Map<String, dynamic> user) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          // Profile Image
          CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage(user['image']),
            onBackgroundImageError: (_, __) {},
            child: user['image'] == null ? const Icon(Icons.person) : null,
          ),
          const SizedBox(width: 12),
          
          // Username and Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['username'],
                  style: const TextStyle(
                    color: Color(0xFF2A9D8F),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  user['name'],
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Following Button
          Container(
            height: 30,
            margin: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              onPressed: () {
                _unfollowUser(user['id'], user['username']);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF90D4CE),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                minimumSize: const Size(80, 30),
              ),
              child: const Text(
                'Following',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
          
          // More Options Button
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            onPressed: () {
              _showMoreOptions(context, user);
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions(BuildContext context, Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_remove, color: Color(0xFF2A9D8F)),
                title: const Text('Unfollow'),
                onTap: () {
                  Navigator.pop(context);
                  _unfollowUser(user['id'], user['username']);
                },
              ),
              ListTile(
                leading: Icon(
                  user['notifications_enabled'] ? Icons.notifications_off : Icons.notifications,
                  color: const Color(0xFF2A9D8F),
                ),
                title: Text(user['notifications_enabled'] ? 'Turn off notifications' : 'Turn on notifications'),
                onTap: () {
                  Navigator.pop(context);
                  _toggleNotifications(user['id'], user['notifications_enabled']);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}