import 'package:flutter/material.dart';
import '../profile/Profile.dart';
import '../search/Search.dart';
import '../search/DetailMenu.dart';
import '../community/Community.dart';
import 'AddReviews.dart';
import '../home/HomePage.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/review.dart';
import 'dart:convert';

class Reviews extends StatelessWidget {
  final int recipeId;
  final String? uploaderName;
  final String? uploaderUsername;
  final String? uploaderFoto;
  final String? recipeName;
  final String? recipeFoto;
  final double? avgRating;
  final int? reviewsCount;

  const Reviews({
    Key? key,
    required this.recipeId,
    this.uploaderName,
    this.uploaderUsername,
    this.uploaderFoto,
    this.recipeName,
    this.recipeFoto,
    this.avgRating,
    this.reviewsCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF008080),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: ReviewsPage(
        recipeId: recipeId,
        uploaderName: uploaderName,
        uploaderUsername: uploaderUsername,
        uploaderFoto: uploaderFoto,
        recipeName: recipeName,
        recipeFoto: recipeFoto,
        avgRating: avgRating,
        reviewsCount: reviewsCount,
      ),
    );
  }
}

class ReviewsPage extends StatefulWidget {
  final int recipeId;
  final String? uploaderName;
  final String? uploaderUsername;
  final String? uploaderFoto;
  final String? recipeName;
  final String? recipeFoto;
  final double? avgRating;
  final int? reviewsCount;

  const ReviewsPage({
    super.key,
    required this.recipeId,
    this.uploaderName,
    this.uploaderUsername,
    this.uploaderFoto,
    this.recipeName,
    this.recipeFoto,
    this.avgRating,
    this.reviewsCount,
  });

  @override
  _ReviewsPageState createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  int _selectedIndex = 1;
  List<Review> reviews = [];
  bool isLoadingReviews = true;
  bool isLoadingRecipe = true;
  String? errorMessage;

  late int recipeId;

  // Recipe data that will be fetched from database
  String? uploaderName;
  String? uploaderUsername;
  String? uploaderFoto;
  String? recipeName;
  String? recipeFoto;
  double? avgRating;
  int? reviewsCount;

  @override
  void initState() {
    super.initState();
    recipeId = widget.recipeId;

    // Initialize with passed data (fallback)
    uploaderName = widget.uploaderName;
    uploaderUsername = widget.uploaderUsername;
    uploaderFoto = widget.uploaderFoto;
    recipeName = widget.recipeName;
    recipeFoto = widget.recipeFoto;
    avgRating = widget.avgRating;
    reviewsCount = widget.reviewsCount;

    // Fetch all data in one go
    _fetchRecipeDataWithReviews();
  }

  // Fetch recipe data and reviews in one API call
  Future<void> _fetchRecipeDataWithReviews() async {
    setState(() {
      isLoadingRecipe = true;
      isLoadingReviews = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/recipes/$recipeId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Recipe API Response Status: \\${response.statusCode}');
      print('Recipe API Response Body: \\${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('data[data] keys: \\${data['data']?.keys}');
        print('reviews_avg_bintang: \\${data['data']?['reviews_avg_bintang']}');
        print('reviews_count: \\${data['data']?['reviews_count']}');
        var recipeData = data['data']?['recipe'];
        print('recipeData keys: \\${recipeData?.keys}');
        print(
            'recipeData[reviews_avg_bintang]: \\${recipeData?['reviews_avg_bintang']}');
        print('recipeData[reviews_count]: \\${recipeData?['reviews_count']}');
        double? apiAvgRating = recipeData?['reviews_avg_bintang'] != null
            ? double.tryParse(recipeData['reviews_avg_bintang'].toString())
            : null;
        int? apiReviewsCount = recipeData?['reviews_count'] != null
            ? int.tryParse(recipeData['reviews_count'].toString())
            : null;
        setState(() {
          avgRating = apiAvgRating;
          reviewsCount = apiReviewsCount;
          if (recipeData == null) {
            errorMessage = 'Data resep tidak ditemukan di response API.';
            recipeName = null;
            recipeFoto = null;
            uploaderName = null;
            uploaderUsername = null;
            uploaderFoto = null;
            reviews = [];
          } else {
            recipeName = recipeData['nama'];
            recipeFoto = recipeData['foto'];
            uploaderName = recipeData['user_name'];
            uploaderUsername = recipeData['username'];
            uploaderFoto = recipeData['user_foto'];
            reviews = (recipeData['reviews'] as List)
                .map((reviewJson) => Review.fromJson(reviewJson))
                .toList();
            print('Reviews loaded: \\${reviews.length}');
          }
        });
      } else {
        print('API Error: \\${response.statusCode} - \\${response.body}');
        setState(() {
          errorMessage =
              'Gagal mengambil data resep (code: \\${response.statusCode})';
        });
      }
    } catch (e) {
      print('Error fetching recipe data: \\${e}');
      setState(() {
        errorMessage = 'Gagal parsing data resep: \\${e}';
      });
    } finally {
      setState(() {
        isLoadingRecipe = false;
        isLoadingReviews = false;
      });
    }
  }

  Future<void> _refreshReviews() async {
    await _fetchRecipeDataWithReviews();
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

  String? _getImageUrl(String? imageUrl) {
    print('Getting image URL for: $imageUrl');

    if (imageUrl == null || imageUrl.isEmpty) {
      print('Image URL is null or empty, returning null');
      return null;
    }

    if (imageUrl.startsWith('http')) {
      print('Using full URL: $imageUrl');
      return imageUrl;
    }

    // Handle relative paths from database
    String fullUrl = '$baseUrl/storage/$imageUrl';
    print('Constructed URL: $fullUrl');
    return fullUrl;
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    print(
        'BUILD: avgRating=[32m$avgRating[0m, reviewsCount=[32m$reviewsCount[0m');
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailMenu(recipeId: recipeId),
                            ),
                          );
                        },
                        child: const Icon(
                          Icons.arrow_back,
                          color: Color(0xFF008080),
                        ),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Reviews',
                            style: TextStyle(
                              color: Color(0xFF008080),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                    ],
                  ),
                ),
                // Main content
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshReviews,
                    color: const Color(0xFF008080),
                    child: ListView(
                      padding: const EdgeInsets.all(0),
                      children: [
                        // Food item card
                        Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF008080),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: isLoadingRecipe
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(20.0),
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                : (recipeName == null || recipeName!.isEmpty)
                                    ? Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Text(
                                            errorMessage ??
                                                'Gagal memuat detail resep. Coba refresh atau cek koneksi.',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      )
                                    : Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _getImageUrl(recipeFoto) != null
                                              ? ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: Image.network(
                                                    _getImageUrl(recipeFoto)!,
                                                    width: 100,
                                                    height: 100,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context,
                                                        error, stackTrace) {
                                                      print(
                                                          'Image load error: $error');
                                                      print(
                                                          'Failed URL: \\${_getImageUrl(recipeFoto)}');
                                                      return Container(
                                                        width: 100,
                                                        height: 100,
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              Colors.grey[300],
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                        child: const Icon(
                                                          Icons
                                                              .image_not_supported,
                                                          color: Colors.grey,
                                                          size: 40,
                                                        ),
                                                      );
                                                    },
                                                    loadingBuilder: (context,
                                                        child,
                                                        loadingProgress) {
                                                      if (loadingProgress ==
                                                          null) return child;
                                                      return Container(
                                                        width: 100,
                                                        height: 100,
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              Colors.grey[200],
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                        child: const Center(
                                                          child:
                                                              CircularProgressIndicator(
                                                            color: Colors.white,
                                                            strokeWidth: 2,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                )
                                              : Container(
                                                  width: 100,
                                                  height: 100,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[300],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: const Icon(
                                                    Icons.image_not_supported,
                                                    color: Colors.grey,
                                                    size: 40,
                                                  ),
                                                ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  recipeName != null &&
                                                          recipeName!.isNotEmpty
                                                      ? recipeName!
                                                      : 'Gagal memuat nama resep',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    for (int i = 0;
                                                        i <
                                                            (avgRating != null
                                                                ? avgRating!
                                                                    .floor()
                                                                : 0);
                                                        i++)
                                                      const Icon(
                                                        Icons.star,
                                                        color: Colors.white,
                                                        size: 16,
                                                      ),
                                                    if (avgRating != null &&
                                                        avgRating! -
                                                                avgRating!
                                                                    .floor() >=
                                                            0.5)
                                                      const Icon(
                                                        Icons.star_half,
                                                        color: Colors.white,
                                                        size: 16,
                                                      ),
                                                    for (int i = 0;
                                                        i <
                                                            5 -
                                                                (avgRating !=
                                                                        null
                                                                    ? avgRating!
                                                                        .ceil()
                                                                    : 0);
                                                        i++)
                                                      const Icon(
                                                        Icons.star_border,
                                                        color: Colors.white,
                                                        size: 16,
                                                      ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '(${reviewsCount ?? 0} Reviews)',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    _getImageUrl(
                                                                uploaderFoto) !=
                                                            null
                                                        ? CircleAvatar(
                                                            radius: 12,
                                                            backgroundImage:
                                                                NetworkImage(
                                                              _getImageUrl(
                                                                  uploaderFoto)!,
                                                            ),
                                                            backgroundColor:
                                                                Colors
                                                                    .grey[300],
                                                          )
                                                        : CircleAvatar(
                                                            radius: 12,
                                                            backgroundColor:
                                                                Colors
                                                                    .grey[300],
                                                            child: const Icon(
                                                              Icons.person,
                                                              color:
                                                                  Colors.grey,
                                                              size: 16,
                                                            ),
                                                          ),
                                                    const SizedBox(width: 6),
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          uploaderUsername !=
                                                                      null &&
                                                                  uploaderUsername!
                                                                      .isNotEmpty
                                                              ? '@$uploaderUsername'
                                                              : 'Gagal memuat username',
                                                          style:
                                                              const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                        Text(
                                                          uploaderName !=
                                                                      null &&
                                                                  uploaderName!
                                                                      .isNotEmpty
                                                              ? uploaderName!
                                                              : 'Gagal memuat nama uploader',
                                                          style:
                                                              const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 10,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Align(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: ElevatedButton(
                                                    onPressed: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              const ReviewForm(),
                                                        ),
                                                      );
                                                    },
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.white,
                                                      foregroundColor:
                                                          const Color(
                                                              0xFF008080),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                      ),
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 16,
                                                        vertical: 8,
                                                      ),
                                                      minimumSize: Size.zero,
                                                      tapTargetSize:
                                                          MaterialTapTargetSize
                                                              .shrinkWrap,
                                                    ),
                                                    child: const Text(
                                                      'Add Review',
                                                      style: TextStyle(
                                                          fontSize: 12),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(
                            left: 16.0,
                            top: 16.0,
                            bottom: 8.0,
                          ),
                          child: Text(
                            'Comments',
                            style: TextStyle(
                              color: Color(0xFF008080),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        // Loading state
                        if (isLoadingReviews)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: CircularProgressIndicator(
                                color: Color(0xFF008080),
                              ),
                            ),
                          )
                        // Error state
                        else if (errorMessage != null)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                children: [
                                  Text(
                                    errorMessage!,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                  const SizedBox(height: 10),
                                  ElevatedButton(
                                    onPressed: _fetchRecipeDataWithReviews,
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
                        // Reviews list
                        else if (reviews.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text(
                                'No reviews yet',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          )
                        else
                          ...reviews.asMap().entries.map((entry) {
                            Review review = entry.value;
                            final username = review.userUsername != null &&
                                    review.userUsername!.isNotEmpty
                                ? '@${review.userUsername}'
                                : '@user${review.userId}';
                            final avatarUrl = _getImageUrl(review.userFoto);
                            String timeAgo = 'Recently';
                            if (review.createdAt != null &&
                                review.createdAt is String &&
                                review.createdAt!.isNotEmpty) {
                              try {
                                final created =
                                    DateTime.parse(review.createdAt!);
                                timeAgo = _getTimeAgo(created);
                              } catch (e) {
                                timeAgo = 'Recently';
                              }
                            }
                            return _buildCommentItem(
                              username: username,
                              timeAgo: timeAgo,
                              avatarUrl: avatarUrl,
                              rating: review.bintang,
                              comment: review.deskripsi,
                            );
                          }).toList(),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
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
                        decoration: isSelected && index == 1
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
  }

  Widget _buildCommentItem({
    required String username,
    required String timeAgo,
    required String? avatarUrl,
    required int rating,
    String? comment,
  }) {
    String commentText =
        comment ?? 'Makanannya oke, pelayanan juga cepat. Recommended!';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              avatarUrl != null
                  ? CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(avatarUrl),
                      onBackgroundImageError: (exception, stackTrace) {
                        // Handle avatar image error silently
                      },
                    )
                  : CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey[300],
                      child: const Icon(
                        Icons.person,
                        color: Colors.grey,
                        size: 24,
                      ),
                    ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            username,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            timeAgo,
                            style: const TextStyle(
                              color: Colors.teal,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(commentText, style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          for (int i = 0; i < rating; i++)
                            const Icon(Icons.star,
                                color: Colors.teal, size: 16),
                          for (int i = 0; i < (5 - rating); i++)
                            const Icon(
                              Icons.star_border,
                              color: Colors.teal,
                              size: 16,
                            ),
                        ],
                      ),
                    ]),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
