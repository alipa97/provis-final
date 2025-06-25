class Step {
  final int id;
  final int resepId;
  final int no;
  final String deskripsi;

  Step({
    required this.id,
    required this.resepId,
    required this.no,
    required this.deskripsi,
  });

  factory Step.fromJson(Map<String, dynamic> json) {
    return Step(
      id: json['id'],
      resepId: json['resep_id'] ?? 0,
      no: json['no'] ?? 0,
      deskripsi: json['deskripsi'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'resep_id': resepId,
      'no': no,
      'deskripsi': deskripsi,
    };
  }
}
