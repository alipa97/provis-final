import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ← TAMBAH INI
import '../Main.dart';
import '../navbar/custom_navbar.dart';
import '../community/community.dart';
import '../myresep/EditRecipe.dart';
import '../search/Search.dart';
import 'Following.dart' show FollowingPage;
import '../home/HomePage.dart';
import '../auth/Login.dart'; // ← TAMBAH INI
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'dart:convert';

class FollowersPage extends StatefulWidget {
  const FollowersPage({Key? key}) : super(key: key);

  @override
  State<FollowersPage> createState() => _FollowersPageState();
}

class _FollowersPageState extends State<FollowersPage> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 3; // Set to profile tab

  // ← TAMBAH TOKEN MANAGEMENT
  String? authToken;
  
  // State management untuk Followers dan Profile data
  List<Map<String, dynamic>> followers = [];
  bool isLoadingFollowers = true;
  bool isLoadingProfile = true;
  String? followersErrorMessage;
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
        _fetchFollowers(),
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
  Future<void> _fetchFollowers() async {
    if (authToken == null) return;

    setState(() {
      isLoadingFollowers = true;
      followersErrorMessage = null;
    });

    try {
      // UPDATE: Sesuai dengan Node.js endpoint
      final response = await http.get(
        Uri.parse('$baseUrl/profile/followers'), // Node.js: /api/profile/followers
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken', // ← GUNAKAN TOKEN DARI SHARED PREFERENCES
        },
      );

      print('Followers Status: ${response.statusCode}');
      print('Followers Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // UPDATE: Sesuai dengan Node.js response structure
        if (data['status'] == 'success') {
          final followersData = data['data']['followers'] ?? [];
          
          setState(() {
            followers = followersData.map<Map<String, dynamic>>((follower) {
              return {
                'id': follower['id'],
                'username': '@${follower['username'] ?? follower['name']}',
                'name': follower['name'],
                // UPDATE: Handle foto URL dari Node.js
                'image': follower['foto'] != null 
                    ? (follower['foto'].startsWith('http') 
                        ? follower['foto'] 
                        : '$baseUrl${follower['foto']}')
                    : 'https://images.unsplash.com/photo-1494790108377-be9c29b29330',
                'followed_at': follower['followed_at'] ?? '',
                'isFollowing': true, // User ini adalah follower kita, jadi kita bisa follow back
              };
            }).toList();
            
            // Update followers count dari API response
            final stats = data['data']['stats'];
            if (stats != null) {
              followersCount = stats['total_followers'] ?? followers.length;
              followingCount = stats['total_following'] ?? followingCount;
            }
            
            print('Followers loaded: ${followers.length}');
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to load followers');
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
        throw Exception(errorData['message'] ?? 'Failed to load followers');
      }
    } catch (e) {
      print('Error fetching followers: $e');
      setState(() {
        followersErrorMessage = 'Failed to load followers: $e';
        // Fallback data untuk testing (berdasarkan seeder)
        followers = [
          {
            'id': 2,
            'username': '@klarakeren',
            'name': 'Klara Oliviera',
            'image': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330',
            'followed_at': '2024-01-15T10:30:00Z',
            'isFollowing': false,
          },
          {
            'id': 3,
            'username': '@notnaex',
            'name': 'Naeya Adeani',
            'image': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80',
            'followed_at': '2024-01-10T08:20:00Z',
            'isFollowing': true,
          },
          {
            'id': 5,
            'username': '@marchrin',
            'name': 'Ririn Marcelina',
            'image': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
            'followed_at': '2024-01-05T15:45:00Z',
            'isFollowing': false,
          },
        ];
        followersCount = followers.length;
      });
    } finally {
      setState(() {
        isLoadingFollowers = false;
      });
    }
  }

  // ← UPDATE METHOD INI untuk Node.js backend
  Future<void> _toggleFollowUser(int userId, String username, bool isFollowing) async {
    if (authToken == null) return;

    try {
      // UPDATE: Sesuai dengan Node.js endpoint toggle-follow
      final response = await http.post(
        Uri.parse('$baseUrl/profile/toggle-follow/$userId'), // Node.js: /api/profile/toggle-follow/:userId
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      print('Toggle follow status: ${response.statusCode}');
      print('Toggle follow response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // UPDATE: Sesuai dengan Node.js response structure
        if (data['status'] == 'success') {
          final isNowFollowing = data['data']['following'] ?? !isFollowing;
          
          // Update button state locally
          setState(() {
            // Find and update the follower item
            final index = followers.indexWhere((user) => user['id'] == userId);
            if (index != -1) {
              followers[index]['isFollowing'] = isNowFollowing;
            }
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? (isNowFollowing ? 'Following $username' : 'Unfollowed $username')),
              backgroundColor: const Color(0xFF2A9D8F),
            ),
          );
        } else {
          throw Exception(data['message'] ?? 'Failed to toggle follow');
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
        throw Exception(errorData['message'] ?? 'Failed to toggle follow');
      }
    } catch (e) {
      print('Error toggling follow: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ← UPDATE METHOD INI - Note: Node.js backend belum punya endpoint remove follower
  Future<void> _removeFollower(int userId, String username) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Follower'),
          content: Text('Are you sure you want to remove $username from your followers?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                
                // Remove from local list immediately for better UX
                setState(() {
                  followers.removeWhere((user) => user['id'] == userId);
                  followersCount = followers.length;
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Removed $username from followers'),
                    backgroundColor: const Color(0xFF2A9D8F),
                  ),
                );
                
                // NOTE: Node.js backend belum punya endpoint remove follower
                // Bisa tambahkan endpoint DELETE /api/profile/remove-follower/:userId jika diperlukan
                // try {
                //   final response = await http.delete(
                //     Uri.parse('$baseUrl/profile/remove-follower/$userId'),
                //     headers: {
                //       'Content-Type': 'application/json',
                //       'Authorization': 'Bearer $authToken',
                //     },
                //   );
                //   
                //   if (response.statusCode != 200) {
                //     // Revert changes if API call fails
                //     _refreshAll();
                //   }
                // } catch (e) {
                //   // Revert changes if API call fails
                //   _refreshAll();
                // }
              },
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // ← TAMBAH SEARCH FUNCTIONALITY
  Future<void> _searchFollowers(String query) async {
    if (authToken == null || query.isEmpty) {
      _fetchFollowers(); // Reset ke semua followers
      return;
    }

    setState(() {
      isLoadingFollowers = true;
      followersErrorMessage = null;
    });

    try {
      // UPDATE: Gunakan search query parameter
      final response = await http.get(
        Uri.parse('$baseUrl/profile/followers?search=$query'), // Node.js mendukung search query
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      print('Search followers status: ${response.statusCode}');
      print('Search followers response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'success') {
          final followersData = data['data']['followers'] ?? [];
          
          setState(() {
            followers = followersData.map<Map<String, dynamic>>((follower) {
              return {
                'id': follower['id'],
                'username': '@${follower['username'] ?? follower['name']}',
                'name': follower['name'],
                'image': follower['foto'] != null 
                    ? (follower['foto'].startsWith('http') 
                        ? follower['foto'] 
                        : '$baseUrl${follower['foto']}')
                    : 'https://images.unsplash.com/photo-1494790108377-be9c29b29330',
                'followed_at': follower['followed_at'] ?? '',
                'isFollowing': true,
              };
            }).toList();
            
            print('Search results: ${followers.length} followers found');
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to search followers');
        }
      } else {
        throw Exception('Failed to search followers');
      }
    } catch (e) {
      print('Error searching followers: $e');
      setState(() {
        followersErrorMessage = 'Failed to search followers: $e';
        followers = []; // Clear results on error
      });
    } finally {
      setState(() {
        isLoadingFollowers = false;
      });
    }
  }

  // Refresh functions
  Future<void> _refreshAll() async {
    await Future.wait([
      _fetchProfile(),
      _fetchFollowers(),
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
                  child: _buildFollowersList(),
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
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FollowingPage()),
                      );
                    },
                    child: Text(
                      // Dynamic count dari API
                      isLoadingProfile 
                        ? 'Loading...' 
                        : '$followingCount Following',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
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
                      isLoadingFollowers 
                        ? 'Loading...' 
                        : '$followersCount Followers',
                      style: const TextStyle(
                        color: Color(0xFF2A9D8F),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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
            _fetchFollowers(); // Reset jika search kosong
          } else {
            _searchFollowers(value); // Search dengan query
          }
        },
      ),
    );
  }

  Widget _buildFollowersList() {
    // Loading state
    if (isLoadingFollowers) {
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
    if (followersErrorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                followersErrorMessage!,
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
    if (followers.isEmpty) {
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
                    ? 'No followers found for "${_searchController.text}"'
                    : 'No followers found.',
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
    
    // Success state - tampilkan followers dengan RefreshIndicator
    return RefreshIndicator(
      onRefresh: _refreshAll,
      color: const Color(0xFF2A9D8F),
      child: ListView.builder(
        itemCount: followers.length,
        padding: const EdgeInsets.all(0),
        itemBuilder: (context, index) {
          final user = followers[index];
          return _buildFollowerItem(user);
        },
      ),
    );
  }

  Widget _buildFollowerItem(Map<String, dynamic> user) {
    final bool isFollowing = user['isFollowing'] ?? false; // Default false untuk follow back
    
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
          
          // Following/Follow Button
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              onPressed: () {
                _toggleFollowUser(user['id'], user['username'], isFollowing);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isFollowing ? Colors.white : const Color(0xFF2A9D8F),
                foregroundColor: isFollowing ? const Color(0xFF2A9D8F) : Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                side: isFollowing ? const BorderSide(color: Color(0xFF2A9D8F)) : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                minimumSize: const Size(80, 30),
              ),
              child: Text(
                isFollowing ? 'Following' : 'Follow Back',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          
          // Remove Button
          ElevatedButton(
            onPressed: () {
              _removeFollower(user['id'], user['username']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF90D4CE),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              minimumSize: const Size(80, 30),
            ),
            child: const Text(
              'Remove',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}