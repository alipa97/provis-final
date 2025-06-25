class Review {
  final int id;
  final int resepId;
  final int userId;
  final String deskripsi;
  final int bintang;
  final String? foto;
  final String? userName;
  final String? userUsername;
  final String? userFoto;
  final String? createdAt;

  Review({
    required this.id,
    required this.resepId,
    required this.userId,
    required this.deskripsi,
    required this.bintang,
    this.foto,
    this.userName,
    this.userUsername,
    this.userFoto,
    this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    final user = json['user'] ?? {};
    return Review(
      id: json['id'],
      resepId: json['resep_id'] ?? json['recipe_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      deskripsi: json['deskripsi'] ?? '',
      bintang: json['bintang'] ?? 0,
      foto: json['foto'],
      userName: user['name'] ?? json['user_name'],
      userUsername: user['username'] ?? json['username'],
      userFoto: user['foto'] ?? json['user_foto'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'resep_id': resepId,
      'user_id': userId,
      'deskripsi': deskripsi,
      'bintang': bintang,
      'foto': foto,
      'user': {
        'name': userName,
        'username': userUsername,
        'foto': userFoto,
      },
      'created_at': createdAt,
    };
  }
}
