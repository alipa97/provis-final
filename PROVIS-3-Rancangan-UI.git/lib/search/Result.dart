import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../community/Community.dart';
import '../profile/Profile.dart';
import '../search/DetailMenu.dart';
import '../home/HomePage.dart';
import '../models/recipe.dart';
import 'dart:convert';

class ResultPage extends StatefulWidget {
  final String? keyword;
  final String? jenisHidangan;
  final String? estimasiWaktu;
  final String? tingkatKesulitan;
  final String? bahan;
  const ResultPage({
    Key? key,
    this.keyword,
    this.jenisHidangan,
    this.estimasiWaktu,
    this.tingkatKesulitan,
    this.bahan,
  }) : super(key: key);

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  late Future<List<Recipes>> searchResultsFuture;

  @override
  void initState() {
    super.initState();
    searchResultsFuture = fetchSearchResults();
  }

  Future<List<Recipes>> fetchSearchResults() async {
    final baseUrl = 'http://localhost:3000/api/search';
    final params = <String, String>{};
    if (widget.keyword != null && widget.keyword!.isNotEmpty) {
      params['keyword'] = widget.keyword!;
    }
    if (widget.jenisHidangan != null && widget.jenisHidangan!.isNotEmpty) {
      params['jenis_hidangan'] = widget.jenisHidangan!;
    }
    if (widget.estimasiWaktu != null && widget.estimasiWaktu!.isNotEmpty) {
      params['estimasi_waktu'] = widget.estimasiWaktu!;
    }
    if (widget.tingkatKesulitan != null &&
        widget.tingkatKesulitan!.isNotEmpty) {
      params['tingkat_kesulitan'] = widget.tingkatKesulitan!;
    }
    if (widget.bahan != null && widget.bahan!.isNotEmpty) {
      params['bahan'] = widget.bahan!;
    }
    final url = Uri.parse(
      baseUrl,
    ).replace(queryParameters: params.isNotEmpty ? params : null);
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results']['data'] ?? [];
      return results.map((json) => Recipes.fromJson(json)).toList();
    } else {
      throw Exception('Gagal fetch hasil pencarian!');
    }
  }

  void _onNavItemTapped(int index) {
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
          MaterialPageRoute(builder: (_) => const CommunityScreen()),
        );
        break;
      case 2:
        // Stay on ResultPage
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
        child: Stack(
          children: [
            Column(
              children: [
                // App Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.teal),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD3EDEE),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const TextField(
                            decoration: InputDecoration(
                              hintText: 'Search',
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.teal,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.notifications_none, color: Colors.teal),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Result",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: FutureBuilder<List<Recipes>>(
                      future: searchResultsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: \\${snapshot.error}'),
                          );
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Center(child: Text('No results found.'));
                        }
                        final recipes = snapshot.data!;
                        return GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.7,
                          children:
                              recipes.map((recipe) {
                                return FoodCard(
                                  imageUrl:
                                      recipe.foto ??
                                      'https://via.placeholder.com/180x120',
                                  title: recipe.nama,
                                  description: recipe.kategori,
                                  rating: recipe.avgRating ?? 0,
                                  duration: recipe.durasi,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) =>
                                                DetailMenu(recipeId: recipe.id),
                                      ),
                                    );
                                  },
                                );
                              }).toList(),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),

            // Custom Bottom Navigation
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 280,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _navItem(Icons.home_outlined, 0),
                      _navItem(Icons.group_outlined, 1),
                      _navItem(Icons.search, 2, isSelected: true),
                      _navItem(Icons.person_outline, 3),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, int index, {bool isSelected = false}) {
    return GestureDetector(
      onTap: () => _onNavItemTapped(index),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration:
            isSelected
                ? const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.white, width: 2),
                  ),
                )
                : null,
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class FoodCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String description;
  final num rating;
  final String duration;
  final VoidCallback onTap;

  const FoodCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.rating,
    required this.duration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
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
                    width: double.infinity,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                const Positioned(
                  right: 8,
                  top: 8,
                  child: Icon(Icons.favorite_border, color: Colors.white),
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
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(description, style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.teal),
                      Text(" $rating", style: const TextStyle(fontSize: 12)),
                      const Spacer(),
                      Icon(Icons.timer, size: 16, color: Colors.teal[300]),
                      Text(
                        " $duration",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
