class User {
  final int id;
  final String name;
  final String email;
  final String username;
  final String noHp;
  final String tanggalLahir;
  final String gender;
  final String foto;
  final int? communityId;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    required this.noHp,
    required this.tanggalLahir,
    required this.gender,
    required this.foto,
    // required this.presentation,
    // required this.addLink,
    this.communityId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      noHp: json['no_hp'] ?? '',
      tanggalLahir: json['tanggal_lahir'] ?? '',
      gender: json['gender'] ?? '',
      foto: json['foto'] ?? '',
      communityId: json['community_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'username': username,
      'no_hp': noHp,
      'tanggal_lahir': tanggalLahir,
      'gender': gender,
      'foto': foto,
      'community_id': communityId,
    };
  }
}