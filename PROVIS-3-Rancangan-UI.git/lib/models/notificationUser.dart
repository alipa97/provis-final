class NotificationUser {
  final int notificationId;
  final int userId;
  final String? readAt;
  final Notification notification;

  NotificationUser({
    required this.notificationId,
    required this.userId,
    this.readAt,
    required this.notification,
  });

  // Check if notification is read
  bool get isRead => readAt != null;

  factory NotificationUser.fromJson(Map<String, dynamic> json) {
    return NotificationUser(
      notificationId: json['notification_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      readAt: json['read_at'], // Bisa null jika belum dibaca
      notification: Notification.fromJson(json['notification'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notification_id': notificationId,
      'user_id': userId,
      'read_at': readAt,
      'notification': notification.toJson(),
    };
  }
}

class Notification {
  final int id;
  final String judul;
  final String deskripsi;
  final String createdAt;
  final String updatedAt;

  Notification({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] ?? 0,
      judul: json['judul'] ?? '',
      deskripsi: json['deskripsi'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'judul': judul,
      'deskripsi': deskripsi,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

// Model untuk response dari backend API
class NotificationResponse {
  final List<NotificationUser> notifications;

  NotificationResponse({required this.notifications});

  factory NotificationResponse.fromJson(List<dynamic> jsonList) {
    return NotificationResponse(
      notifications: jsonList
          .map((json) => NotificationUser.fromJson(json))
          .toList(),
    );
  }
}

// Model untuk unread count response
class UnreadCountResponse {
  final int unreadCount;

  UnreadCountResponse({required this.unreadCount});

  factory UnreadCountResponse.fromJson(Map<String, dynamic> json) {
    return UnreadCountResponse(
      unreadCount: json['unread_count'] ?? 0,
    );
  }
}

// Model untuk mark as read response
class MarkReadResponse {
  final String message;
  final int? count;

  MarkReadResponse({
    required this.message,
    this.count,
  });

  factory MarkReadResponse.fromJson(Map<String, dynamic> json) {
    return MarkReadResponse(
      message: json['message'] ?? '',
      count: json['count'],
    );
  }
}