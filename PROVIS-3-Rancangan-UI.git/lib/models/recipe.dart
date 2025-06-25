import 'step.dart';
import 'review.dart';
import 'user.dart';
import 'ingredient.dart';

class Recipes {
  final int id;
  final int userId;
  final String nama;
  final String? foto;
  final String detail;
  final String durasi;
  final String kategori;
  final String jenisHidangan;
  final String estimasiWaktu;
  final String tingkatKesulitan;
  final double? avgRating;
  final List<Step>? steps;
  final List<Review>? reviews;
  final List<Ingredient>? ingredients;
  final int? reviewsCount;
  final int? stepsCount;
  final String nama_user;
  final String username;
  final String foto_user;
  final int? ingredientsCount;

  Recipes({
    required this.id,
    required this.userId,
    required this.nama,
    this.foto,
    required this.detail,
    required this.durasi,
    required this.kategori,
    required this.jenisHidangan,
    required this.estimasiWaktu,
    required this.tingkatKesulitan,
    this.avgRating,
    this.steps,
    this.reviews,
    // this.user,
    this.ingredients,
    this.reviewsCount,
    this.stepsCount,
    required this.nama_user,
    required this.foto_user,
    required this.username,
    this.ingredientsCount,
  });

  factory Recipes.fromJson(Map<String, dynamic> json) {
    return Recipes(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      nama: json['nama'] ?? '',
      foto: json['foto'], // null jika tidak ada
      detail: json['detail'] ?? '',
      durasi: json['durasi'] ?? '',
      kategori: json['kategori'] ?? '',
      jenisHidangan: json['jenis_hidangan'] ?? '',
      estimasiWaktu: json['estimasi_waktu'] ?? '',
      tingkatKesulitan: json['tingkat_kesulitan'] ?? '',
      avgRating: (json['reviews_avg_bintang'] as num?)?.toDouble(),
      steps: (json['steps'] as List<dynamic>?)
          ?.map((e) => Step.fromJson(e))
          .toList(),
      reviews: (json['reviews'] as List<dynamic>?)
          ?.map((e) => Review.fromJson(e))
          .toList(),
      // user: json['user'] != null ? User.fromJson(json['user']) : null,
      ingredients: (json['ingredients'] as List<dynamic>?)
          ?.map((e) => Ingredient.fromJson(e))
          .toList(),
      reviewsCount: json['reviews_count'] ?? 0,
      stepsCount: json['steps_count'] ?? 0,
      ingredientsCount: json['ingredients_count'] ?? 0,
      nama_user: json['user_name'] ?? '',
      username: json['username'] ?? '',
      foto_user: json['user_foto'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'nama': nama,
      'foto': foto,
      'detail': detail,
      'durasi': durasi,
      'kategori': kategori,
      'jenis_hidangan': jenisHidangan,
      'estimasi_waktu': estimasiWaktu,
      'tingkat_kesulitan': tingkatKesulitan,
      'steps': steps?.map((s) => s.toJson()).toList(),
      'reviews': reviews?.map((r) => r.toJson()).toList(),
      // 'user': user?.toJson(),
      'ingredients': ingredients?.map((i) => i.toJson()).toList(),
      'reviews_avg_bintang': avgRating,
      'reviews_count': reviewsCount,
      'steps_count': stepsCount,
      'user_name': nama_user,
      'username': username,
      'user_foto': foto_user,
      'ingredients_count': ingredientsCount,
    };
  }
}
