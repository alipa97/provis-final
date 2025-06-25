import 'user.dart';
import 'recipe.dart';

class Community {
  final int id;
  final String nama;
  final List<User> users;
  final List<Recipes> recipes;

  Community({
    required this.id,
    required this.nama,
    required this.users,
    required this.recipes,
  });

  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      id: json['community']['id'],
      nama: json['community']['nama'] ?? '',
      users:
          (json['users'] as List)
              .map((userJson) => User.fromJson(userJson))
              .toList(),
      recipes:
          (json['recipes'] as List)
              .map((recipeJson) => Recipes.fromJson(recipeJson))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'users': users.map((u) => u.toJson()).toList(),
      'recipes': recipes.map((r) => r.toJson()).toList(),
    };
  }
}
