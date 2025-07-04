import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/recipe.dart';
import '../profile/Profile.dart';
import '../search/Search.dart';
import '../community/Community.dart';
import '../home/HomePage.dart';
import '../reviews/Reviews.dart';
import '../utils/constants.dart';

class DetailMenu extends StatelessWidget {
  final int recipeId;
  const DetailMenu({Key? key, required this.recipeId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Recipe App',
      theme: ThemeData(
        primaryColor: const Color(0xFF2A9D8F),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2A9D8F),
          primary: const Color(0xFF2A9D8F),
        ),
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: Colors.white,
      ),
      home: DetailMenuScreen(recipeId: recipeId),
    );
  }
}

class DetailMenuScreen extends StatefulWidget {
  final int recipeId;
  const DetailMenuScreen({Key? key, required this.recipeId}) : super(key: key);

  @override
  _DetailMenuScreenState createState() => _DetailMenuScreenState();
}

class _DetailMenuScreenState extends State<DetailMenuScreen> {
  int _selectedIndex = 0;
  List<bool> _isFavorited = [];
  late Future<Recipes> recipeDetail;

  @override
  void initState() {
    super.initState();
    _selectedIndex = 1;
    _isFavorited = List<bool>.filled(10, false);
    recipeDetail = fetchRecipeDetail(widget.recipeId);
  }

  Future<Recipes> fetchRecipeDetail(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/recipes/$id'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final recipeJson = data['data']['recipe'];
      return Recipes.fromJson(recipeJson);
    } else {
      throw Exception('Failed to load recipe detail');
    }
  }

  String _getImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return 'https://via.placeholder.com/300x200';
    }

    // Jika sudah berupa URL lengkap, replace localhost untuk emulator
    if (imageUrl.startsWith('http')) {
      return imageUrl;
    }

    // Jika hanya path, buat URL lengkap
    return 'http://10.0.2.2:8000/storage/$imageUrl';
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<Recipes>(
          future: recipeDetail,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                  child: Text('Terjadi kesalahan: \${snapshot.error}'));
            } else if (!snapshot.hasData) {
              return const Center(child: Text('Resep tidak ditemukan.'));
            }

            final recipe = snapshot.data!;

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error:  {snapshot.error}'));
            } else if (!snapshot.hasData) {
              return const Center(child: Text('No data'));
            }

            // 🔍 DEBUG PRINT - Tambahkan di sini
            print('Raw foto from API: ${recipe.foto}');
            print('Processed Image URL: ${_getImageUrl(recipe.foto)}');

            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header bar
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.teal,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                        const Spacer(),
                        Text(
                          recipe.nama,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.teal,
                            shape: BoxShape.circle,
                          ),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isFavorited[0] = !_isFavorited[0];
                              });
                            },
                            child: Icon(
                              _isFavorited[0]
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.teal,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.share,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Image with overlaid title and icons
                  Center(
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _getImageUrl(recipe.foto),
                            width: 300,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 300,
                                height: 200,
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.image_not_supported,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 300,
                                height: 200,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          child: Container(
                            width: 300,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.teal,
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  recipe.nama,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                        size: 16,
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                Reviews(
                                                  recipeId: recipe.id,
                                                  uploaderName: recipe.nama_user,
                                                  uploaderUsername: recipe.username,
                                                  uploaderFoto: recipe.foto_user,
                                                  recipeName: recipe.nama,
                                                  recipeFoto: recipe.foto,
                                                  avgRating: recipe.avgRating,
                                                  reviewsCount: recipe.reviewsCount,
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      recipe.avgRating?.toStringAsFixed(1) ??
                                          '-', // tampilkan satu angka di belakang koma
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.comment,
                                        color: Colors.grey,
                                        size: 16,
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                Reviews(recipeId: recipe.id),
                                          ),
                                        );
                                      },
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      recipe.reviewsCount?.toString() ?? '0',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Author Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundImage: NetworkImage(
                            'https://images.unsplash.com/photo-1513104890138-7c749659a591',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment
                              .start, // opsional biar rata kiri
                          children: [
                            Text(
                              recipe.username.isNotEmpty
                                  ? '@${recipe.username}'
                                  : 'Tanpa Nama',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              recipe.nama_user.isNotEmpty
                                  ? recipe.nama_user
                                  : 'Tanpa Nama',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.teal[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Following',
                            style: TextStyle(color: Colors.teal),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.more_vert, color: Colors.teal),
                      ],
                    ),
                  ),

                  const Divider(indent: 16, endIndent: 16),

                  // Detail Section with time on the right
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        const Text(
                          'Detail',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2A9D8F),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          recipe.durasi,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      recipe.detail,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Ingredients
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Bahan-Bahan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Ingredients placeholder
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: recipe.ingredients?.map((ingredient) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                '• ${ingredient.bahan}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList() ??
                          [const Text('-')],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Steps
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '${recipe.stepsCount?.toString() ?? '0'} Langkah Mudah',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ),
                  // Steps placeholder
                  const SizedBox(height: 12),
                  const SizedBox(height: 12),
                  // Langkah-langkah resep
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: recipe.steps?.map((step) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.teal[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${step.deskripsi}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList() ??
                          [const Text('-')], // fallback jika steps null
                    ),
                  ),

                  // Custom Bottom Navigation
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 240,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.teal,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(4, (index) {
                            final icons = [
                              Icons.home_outlined,
                              Icons.chat_bubble_outline,
                              Icons.search,
                              Icons.person_outline,
                            ];

                            final isSelected = _selectedIndex == index;

                            return GestureDetector(
                              onTap: () => _onNavItemTapped(index),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: isSelected &&
                                        index ==
                                            1 // Ensure only bubble chat is underlined
                                    ? const BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                      )
                                    : null,
                                child: Icon(icons[index], color: Colors.white),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
