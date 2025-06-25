import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ← TAMBAH INI
import '../Main.dart';
import '../navbar/custom_navbar.dart';
import '../community/community.dart';
import '../myresep/EditRecipe.dart';
import '../search/Search.dart';
import 'Following.dart' show FollowingPage;
import 'Followers.dart' show FollowersPage;
import '../profile/EditProfile.dart';
import '../profile/ShareProfile.dart';
import '../home/HomePage.dart';
import '../auth/Login.dart'; // ← TAMBAH INI
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'dart:convert';

class ProfileRecipePage extends StatefulWidget {
  const ProfileRecipePage({Key? key}) : super(key: key);

  @override
  State<ProfileRecipePage> createState() => _ProfileRecipePageState();
}

class _ProfileRecipePageState extends State<ProfileRecipePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 3;

  // ← TAMBAH TOKEN MANAGEMENT
  String? authToken;

  // State management untuk Profile data
  bool isLoadingProfile = true;
  bool isLoadingRecipes = true;
  bool isLoadingFavorites = true;
  String? profileErrorMessage;
  String? recipesErrorMessage;
  String? favoritesErrorMessage;

  // User profile data - akan diambil dari API
  Map<String, dynamic> userProfile = {};
  Map<String, dynamic> profileStats = {};
  List<Map<String, dynamic>> userRecipes = [];
  List<Map<String, dynamic>> favoriteRecipes = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTokenAndFetchProfile(); // ← GANTI METHOD
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ← TAMBAH METHOD LOAD TOKEN
  Future<void> _loadTokenAndFetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      authToken = prefs.getString('auth_token');
    });
    
    if (authToken != null) {
      await _fetchProfileData();
    } else {
      // Redirect ke login
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
        (route) => false,
      );
    }
  }

  // Fetch semua data profile
  Future<void> _fetchProfileData() async {
    await _fetchProfile();
  }

  // ← UPDATE METHOD INI untuk Node.js backend
  Future<void> _fetchProfile() async {
    if (authToken == null) return;

    setState(() {
      isLoadingProfile = true;
      isLoadingRecipes = true;
      isLoadingFavorites = true;
      profileErrorMessage = null;
    });

    try {
      // UPDATE: Sesuai dengan Node.js endpoint
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
        
        // UPDATE: Sesuai dengan Node.js response structure
        if (data['status'] == 'success') {
          final responseData = data['data'];
          
          setState(() {
            // User profile data
            userProfile = responseData['user'];
            profileStats = responseData['stats'];
            
            // User recipes - UPDATE sesuai Node.js structure
            userRecipes = (responseData['recipes'] as List).map((recipe) {
              return {
                'id': recipe['id'],
                'title': recipe['nama'],
                'description': recipe['deskripsi'] ?? 'No description',
                'image': recipe['foto'] ?? 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c',
                'rating': (recipe['reviews_avg_bintang'] != null) 
                    ? double.tryParse(recipe['reviews_avg_bintang'].toString()) ?? 0.0 
                    : 0.0,
                'time': '${recipe['durasi']}min',
                'isFavorite': false, // Will be updated based on favorites
                'reviews_count': recipe['reviews_count'] ?? 0,
              };
            }).toList();
            
            // Favorite recipes - UPDATE sesuai Node.js structure
            favoriteRecipes = (responseData['favorites'] as List).map((recipe) {
              return {
                'id': recipe['id'],
                'title': recipe['nama'],
                'description': recipe['deskripsi'] ?? 'No description',
                'image': recipe['foto'] ?? 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c',
                'rating': (recipe['reviews_avg_bintang'] != null) 
                    ? double.tryParse(recipe['reviews_avg_bintang'].toString()) ?? 0.0 
                    : 0.0,
                'time': '${recipe['durasi']}min',
                'isFavorite': true,
                'reviews_count': recipe['reviews_count'] ?? 0,
                'user': recipe['user'] ?? {}, // User info from Node.js
              };
            }).toList();
            
            // Update isFavorite for user recipes
            for (var recipe in userRecipes) {
              recipe['isFavorite'] = favoriteRecipes.any((fav) => fav['id'] == recipe['id']);
            }
            
            print('Profile loaded - User: ${userProfile['name']}, Recipes: ${userRecipes.length}, Favorites: ${favoriteRecipes.length}');
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
        userProfile = {
          'id': 1,
          'name': 'Alifa Bee',
          'username': 'alifabee',
          'email': 'alifa@example.com',
          'foto': null,
        };
        profileStats = {
          'total_recipes': 4,
          'total_followers': 3,
          'total_following': 2,
          'total_favorites': 4,
        };
        userRecipes = [
          {
            'id': 1,
            'title': 'Béchamel Pasta',
            'description': 'A creamy and indulgent pasta dish',
            'image': 'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9',
            'rating': 4.0,
            'time': '30min',
            'isFavorite': false,
            'reviews_count': 5,
          },
          {
            'id': 2,
            'title': 'Grilled Skewers',
            'description': 'Succulent morsels grilled to perfection',
            'image': 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1',
            'rating': 4.0,
            'time': '25min',
            'isFavorite': true,
            'reviews_count': 8,
          },
        ];
        favoriteRecipes = [
          {
            'id': 3,
            'title': 'French Toast',
            'description': 'Delicious slices of bread dipped in egg mixture',
            'image': 'https://images.unsplash.com/photo-1484723091739-30a097e8f929',
            'rating': 5.0,
            'time': '20min',
            'isFavorite': true,
            'reviews_count': 12,
          },
          {
            'id': 4,
            'title': 'Fruit Crepes',
            'description': 'Fruity-filled chocolate crepes',
            'image': 'https://images.unsplash.com/photo-1519676867240-f03562e64548',
            'rating': 4.5,
            'time': '30min',
            'isFavorite': true,
            'reviews_count': 6,
          },
        ];
      });
    } finally {
      setState(() {
        isLoadingProfile = false;
        isLoadingRecipes = false;
        isLoadingFavorites = false;
      });
    }
  }

  // ← UPDATE METHOD INI untuk Node.js
  Future<void> _toggleFavorite(int recipeId, bool currentStatus) async {
    if (authToken == null) return;

    try {
      // UPDATE: Sesuai dengan Node.js endpoint
      final response = await http.post(
        Uri.parse('$baseUrl/profile/toggle-favorite/$recipeId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      print('Toggle favorite status: ${response.statusCode}');
      print('Toggle favorite response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // UPDATE: Sesuai dengan Node.js response
        if (data['status'] == 'success') {
          final newStatus = data['favorited'] ?? !currentStatus;
          
          setState(() {
            // Update in user recipes
            final recipeIndex = userRecipes.indexWhere((recipe) => recipe['id'] == recipeId);
            if (recipeIndex != -1) {
              userRecipes[recipeIndex]['isFavorite'] = newStatus;
            }
            
            // Update favorites list
            if (newStatus) {
              // Add to favorites if not already there
              final recipe = userRecipes.firstWhere((r) => r['id'] == recipeId);
              if (!favoriteRecipes.any((fav) => fav['id'] == recipeId)) {
                favoriteRecipes.add(recipe);
              }
            } else {
              // Remove from favorites
              favoriteRecipes.removeWhere((fav) => fav['id'] == recipeId);
            }
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? (newStatus ? 'Added to favorites' : 'Removed from favorites')),
              backgroundColor: const Color(0xFF2A9D8F),
            ),
          );
        } else {
          throw Exception(data['message'] ?? 'Failed to update favorite');
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
        throw Exception(errorData['message'] ?? 'Failed to update favorite');
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating favorite: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Refresh function
  Future<void> _refreshProfile() async {
    await _fetchProfileData();
  }

  // ← TAMBAH LOGOUT METHOD
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const Login()),
      (route) => false,
    );
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildProfileHeader(),
                _buildProfileActions(),
                _buildProfileStats(),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRecipeGrid(), // Recipe tab content
                      _buildFavoritesGrid(), // Favorites tab content
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
          CustomNavbar(
            selectedIndex: _selectedIndex,
            onItemTapped: _onNavItemTapped,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    if (isLoadingProfile) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF2A9D8F)),
        ),
      );
    }

    // UPDATE: Sesuai dengan Node.js response - tidak ada nested storage path
    final profileImageUrl = userProfile['foto'] != null 
        ? (userProfile['foto'].startsWith('http') 
            ? userProfile['foto'] 
            : '$baseUrl${userProfile['foto']}') // Node.js mengembalikan path lengkap
        : 'https://images.unsplash.com/photo-1494790108377-be9c29b29330';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: NetworkImage(profileImageUrl),
                fit: BoxFit.cover,
              ),
              border: Border.all(
                color: const Color(0xFF2A9D8F),
                width: 2,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userProfile['name'] ?? 'Unknown User',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2A9D8F),
                  ),
                ),
                Text(
                  '@${userProfile['username'] ?? 'username'}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                
              ],
            ),
          ),
          Column(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFAFDED9),
                radius: 16,
                child: IconButton(
                  icon: const Icon(Icons.add, size: 16, color: Color(0xFF2A9D8F)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditRecipePage(),
                      ),
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
              const SizedBox(height: 8),
              CircleAvatar(
                backgroundColor: const Color(0xFFAFDED9),
                radius: 16,
                child: IconButton(
                  icon: const Icon(Icons.logout, size: 16, color: Color(0xFF2A9D8F)),
                  onPressed: () {
                    // ← TAMBAH LOGOUT DIALOG
                    _showLogoutDialog();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ← TAMBAH LOGOUT DIALOG
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _logout();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () async {
                // ← UPDATE: Handle result dari EditProfile
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EditProfile()),
                );
                
                // Refresh profile jika ada update
                if (result == true) {
                  _refreshProfile();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFAFDED9),
                foregroundColor: const Color(0xFF2A9D8F),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Edit Profile',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ShareProfile()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFAFDED9),
                foregroundColor: const Color(0xFF2A9D8F),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Share Profile',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ... rest of the existing methods stay the same ...
  
  Widget _buildProfileStats() {
    if (isLoadingProfile) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF2A9D8F)),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('${profileStats['total_recipes'] ?? 0}', 'recipes'),
          Container(
            height: 30,
            width: 1,
            color: Colors.grey.shade300,
          ),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FollowingPage()),
              );
            },
            child: _buildStatItem('${profileStats['total_following'] ?? 0}', 'Following'),
          ),
          Container(
            height: 30,
            width: 1,
            color: Colors.grey.shade300,
          ),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FollowersPage()),
              );
            },
            child: _buildStatItem('${profileStats['total_followers'] ?? 0}', 'Followers'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey,
            width: 0.5,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF2A9D8F),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFF2A9D8F),
        indicatorWeight: 3,
        tabs: [
          Tab(text: 'Recipe (${userRecipes.length})'),
          Tab(text: 'Favorites (${favoriteRecipes.length})'),
        ],
      ),
    );
  }

  Widget _buildRecipeGrid() {
    if (isLoadingRecipes) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2A9D8F)),
      );
    }

    if (userRecipes.isEmpty) {
      return const Center(
        child: Text(
          'No recipes found. Create your first recipe!',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshProfile,
      color: const Color(0xFF2A9D8F),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: userRecipes.length,
        itemBuilder: (context, index) {
          final recipe = userRecipes[index];
          return _buildRecipeCard(recipe);
        },
      ),
    );
  }

  Widget _buildFavoritesGrid() {
    if (isLoadingFavorites) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2A9D8F)),
      );
    }

    if (favoriteRecipes.isEmpty) {
      return const Center(
        child: Text(
          'No favorite recipes found.',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshProfile,
      color: const Color(0xFF2A9D8F),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: favoriteRecipes.length,
        itemBuilder: (context, index) {
          final recipe = favoriteRecipes[index];
          return _buildRecipeCard(recipe);
        },
      ),
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Image.network(
                  recipe['image'],
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 120,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image, color: Colors.grey),
                    );
                  },
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: IconButton(
                    icon: Icon(
                      recipe['isFavorite'] ? Icons.favorite : Icons.favorite_border,
                      color: recipe['isFavorite'] ? Colors.red : Colors.grey,
                      size: 20,
                    ),
                    onPressed: () {
                      _toggleFavorite(recipe['id'], recipe['isFavorite']);
                    },
                    constraints: const BoxConstraints(
                      minWidth: 30,
                      minHeight: 30,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  recipe['description'],
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${recipe['rating'].toStringAsFixed(1)}',
                          style: const TextStyle(
                            color: Color(0xFF2A9D8F),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.star,
                          color: Color(0xFF2A9D8F),
                          size: 14,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: Colors.grey,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          recipe['time'],
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}