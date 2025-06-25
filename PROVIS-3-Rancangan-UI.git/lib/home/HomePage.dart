import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../profile/Profile.dart';
import '../search/Search.dart';
import '../community/Community.dart';
import '../trending_resep/TrendingResep.dart';
import '../navbar/custom_navbar.dart';
import '../utils/constants.dart';
import '../models/recipe.dart';
import 'dart:convert';
import '../search/DetailMenu.dart';
import '../auth/Login.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  List<String> categories = [];
  bool isLoadingCategories = true;
  String? selectedCategory;
  String? name;

  String? authToken; 

  // State management untuk Your Recipes
  List<Recipes> yourRecipes = [];
  bool isLoadingYourRecipes = true;
  String? yourRecipesErrorMessage;

  // PERBAIKAN: Initialize dengan Future yang sudah completed
  Future<List<Recipes>>? trendingRecipesFuture;
  Future<List<Recipes>>? recentlyAddedFuture;

  @override
  void initState() {
    super.initState();
    _loadToken(); // ← LOAD TOKEN DULU
  }

  
  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      authToken = prefs.getString('auth_token'); // atau 'token'
    });
    
    // Setelah token loaded, baru fetch data
    if (authToken != null) {
      print('Token found: ${authToken?.substring(0, 20)}...');
      _fetchCategories();
      setState(() {
        trendingRecipesFuture = fetchTrendingRecipes();
        recentlyAddedFuture = fetchRecentlyAdded();
      });
      _fetchYourRecipes();
    } else {
      print('No auth token found - redirecting to login');
      // Redirect ke login page
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Login()), // Sesuaikan dengan nama class login Anda
          (route) => false, // Remove semua route sebelumnya
        );
      });
    }
  }

  // State management untuk Your Recipes (sama seperti di Reviews)
  // List<Recipes> yourRecipes = []; // Dynamic recipes from API
  // bool isLoadingYourRecipes = true;
  // String? yourRecipesErrorMessage;

  // late Future<List<Recipes>> trendingRecipesFuture;
  // late Future<List<Recipes>> recentlyAddedFuture;
  // Future<List<Recipes>> fetchTrendingRecipes() async {
  //   final url = Uri.parse('$baseUrl/home'); // tinggal gini

  //   final response = await http.get(url);
  //   if (response.statusCode == 200) {
  //     final List data = json.decode(response.body)['data'];
  //     return data.map((json) => Recipes.fromJson(json)).toList();
  //   } else {
  //     throw Exception('Gagal fetch trending resep!');
  //   }
  // }
  // Fetch categories from API
  // ← UPDATE METHOD INI dengan Authorization header
  Future<void> _fetchCategories() async {
    if (authToken == null) {
      print('No token available');
      return;
    }

    setState(() {
      isLoadingCategories = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/home'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken', // ← TAMBAH INI
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          categories = List<String>.from(data['categories']);
          print('Categories loaded: $categories');
        });
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching categories: $e');
      setState(() {
        categories = ['Breakfast', 'Lunch', 'Dinner', 'Dessert'];
      });
    } finally {
      setState(() {
        isLoadingCategories = false;
      });
    }
  }

  // ← UPDATE METHOD INI dengan Authorization header
  Future<List<Recipes>> fetchTrendingRecipes() async {
    if (authToken == null) {
      throw Exception('No auth token');
    }

    final url = Uri.parse('$baseUrl/home');
    print('Fetching trending with token: ${authToken?.substring(0, 20)}...');
    
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken', // ← TAMBAH INI
      },
    );
    
    print('Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List trendingData = data['trending'];
      return trendingData.map((json) => Recipes.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch trending recipes: ${response.statusCode}');
    }
  }


 // ← UPDATE METHOD INI dengan Authorization header
  Future<void> _fetchYourRecipes() async {
    if (authToken == null) {
      print('No token for your recipes');
      return;
    }

    setState(() {
      isLoadingYourRecipes = true;
      yourRecipesErrorMessage = null;
    });

    try {
      final url = Uri.parse('$baseUrl/home');
      print('Fetching your recipes with token');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken', // ← TAMBAH INI
        },
      );
      
      print('Your recipes status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final user = data['user'];
        name = user?['name'];
        print('Nama user: $name');

        final List yourRecipesData = data['your_recipes'] ?? [];
        
        setState(() {
          yourRecipes = yourRecipesData.map((json) => Recipes.fromJson(json)).toList();
          print('Your recipes loaded: ${yourRecipes.length}');
        });
      } else {
        throw Exception('Failed to load your recipes: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching your recipes: $e');
      setState(() {
        yourRecipesErrorMessage = 'Failed to load your recipes';
        yourRecipes = []; // Clear fallback recipes
      });
    } finally {
      setState(() {
        isLoadingYourRecipes = false;
      });
    }
  }

   // ← UPDATE METHOD INI dengan Authorization header
  Future<List<Recipes>> fetchRecentlyAdded() async {
    if (authToken == null) {
      throw Exception('No auth token');
    }

    final url = Uri.parse('$baseUrl/home');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken', // ← TAMBAH INI
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List recentlyAddedData = data['recently_added'] ?? [];
        return recentlyAddedData.map((json) => Recipes.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load recently added: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching recently added: $e');
      return [];
    }
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        // Already on HomePage, no navigation needed
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
          MaterialPageRoute(builder: (_) => const RecipePage()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfileRecipePage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildCategoryButtons(),
                  const SizedBox(height: 24),
                  _buildTrendingRecipe(),
                  const SizedBox(height: 24),
                  _buildYourRecipes(),
                  const SizedBox(height: 24),
                  _buildRecentlyAdded(),
                  const SizedBox(height: 100), // Space for navigation
                ],
              ),
            ),
          ),
          // Add the CustomNavbar here
          CustomNavbar(
            selectedIndex: _selectedIndex,
            onItemTapped: _onNavItemTapped,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name != null ? 'Hi $name!' : 'Hi!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2A9D8F),
              ),
            ),
            Text(
              'What are you cooking today',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        const CircleAvatar(
          backgroundColor: Color(0xFFE0F5F2),
          radius: 20,
          child: Text(
            'H',
            style: TextStyle(
              color: Color(0xFF2A9D8F),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            categories.map((category) {
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ElevatedButton(
                  onPressed: () {
                    // Kosongkan atau nanti tambahkan aksi sesuai kebutuhan
                    print('Category clicked: $category');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: Text(category),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildTrendingRecipe() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Trending Recipe',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TrendingResepPage(),
                    ),
                  );
                },
                child: const Text(
                  'See All',
                  style: TextStyle(
                    color: Colors.teal,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Recipes>>(
          future: trendingRecipesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No trending recipes found.'));
            }
            final recipes = snapshot.data!;
            return SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: recipes.length,
                itemBuilder: (context, index) {
                  final recipe = recipes[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailMenu(recipeId: recipe.id),
                        ),
                      );
                    },
                    child: Container(
                      width: 180,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child: Image.network(
                              recipe.foto ??
                                  'https://via.placeholder.com/180x120',
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  recipe.nama,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  recipe.durasi,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildYourRecipes() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Your Recipes',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      
      // Loading state
      if (isLoadingYourRecipes)
        const Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(
              color: Color(0xFF008080),
            ),
          ),
        )
      // Error state dengan retry button
      else if (yourRecipesErrorMessage != null)
        Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Text(
                  yourRecipesErrorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _fetchYourRecipes,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF008080),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        )
      // Empty state
      else if (yourRecipes.isEmpty)
        const Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'No recipes found. Create your first recipe!',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        )
      // Success state - tampilkan recipes
      else
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: yourRecipes.length,
            itemBuilder: (context, index) {
              final recipe = yourRecipes[index];
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 12),
                child: _buildRecipeCard(
                  recipe.nama,
                  recipe.foto ?? 'https://via.placeholder.com/160x120',
                  recipe.durasi,
                  4.5,
                ),
              );
            },
          ),
        ),
    ],
  );
}


  Widget _buildRecipeCard(
    String title,
    String imageUrl,
    String time,
    double rating,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.network(
                  imageUrl,
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.teal,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_border,
                    color: Colors.white,
                    size: 18,
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
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      rating.toString(),
                      style: const TextStyle(fontSize: 12),
                    ),
                    const Spacer(),
                    const Icon(Icons.access_time, size: 12, color: Colors.grey),
                    const SizedBox(width: 2),
                    Text(
                      time,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
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

  Widget _buildRecentlyAdded() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recently Added',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Recipes>>(
          future: recentlyAddedFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  'No recently added recipes found.',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }
            final recipes = snapshot.data!;
            return SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: recipes.length,
                itemBuilder: (context, index) {
                  final recipe = recipes[index];
                  return Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 12),
                    child: _buildRecentlyItem(
                      recipe.foto ?? 'https://via.placeholder.com/160x120',
                      recipe.nama,
                      recipe.id,
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentlyItem(String imageUrl, String title, int recipeId) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailMenu(recipeId: recipeId),
          ),
        );
      },
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 120,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported),
                  );
                },
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.teal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_border,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
