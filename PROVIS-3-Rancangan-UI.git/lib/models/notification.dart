class Notification {
  final int id;
  final String judul;
  final String deskripsi;

  Notification({
    required this.id,
    required this.judul,
    required this.deskripsi,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'],
      judul: json['judul'] ?? '',
      deskripsi: json['deskripsi'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'judul': judul,
      'deskripsi': deskripsi,
    };
  }
}
