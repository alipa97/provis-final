class Follower {
  final int id;
  final int fromUserId;
  final int toUserId;

  Follower({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
  });

  factory Follower.fromJson(Map<String, dynamic> json) {
    return Follower(
      id: json['id'] ?? 0,
      fromUserId: json['from_user_id'] ?? 0,
      toUserId: json['to_user_id'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'from_user_id': fromUserId, 'to_user_id': toUserId};
  }
}
