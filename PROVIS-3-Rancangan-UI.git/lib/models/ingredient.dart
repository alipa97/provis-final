class Ingredient {
  final int id;
  final int recipeId;
  final String bahan;

  Ingredient({required this.id, required this.recipeId, required this.bahan});

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'] ?? 0,
      recipeId: json['recipe_id'] ?? 0,
      bahan: json['bahan'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'recipe_id': recipeId, 'bahan': bahan};
  }
}
