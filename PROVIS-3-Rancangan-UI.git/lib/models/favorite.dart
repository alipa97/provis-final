class Favorite {
  final int id;
  final int userId;
  final int recipeId;

  Favorite({required this.id, required this.userId, required this.recipeId});

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      recipeId: json['recipe_id'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'user_id': userId, 'recipe_id': recipeId};
  }
}
