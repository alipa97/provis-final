import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/notificationUser.dart';
import '../utils/constants.dart';
import '../navbar/custom_navbar.dart';
import '../home/HomePage.dart';
import '../community/community.dart';
import '../profile/Profile.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationUser> notifications = [];
  bool isLoading = true;
  String? errorMessage;
  String? authToken;
  int _selectedIndex = 3;

  @override
  void initState() {
    super.initState();
    _loadTokenAndNotifications();
  }

  Future<void> _loadTokenAndNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      authToken = prefs.getString('auth_token');
    });

    if (authToken != null) {
      await _loadNotifications();
    } else {
      setState(() {
        isLoading = false;
        errorMessage = 'Please login to view notifications';
      });
    }
  }

  Future<void> _loadNotifications() async {
    if (authToken == null) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      print('📱 Get notifications response: ${response.statusCode}');
      print('📱 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        setState(() {
          notifications = jsonList
              .map((json) => NotificationUser.fromJson(json))
              .toList();
          isLoading = false;
        });

        print('✅ Loaded ${notifications.length} notifications');
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load notifications: $e';
        isLoading = false;
      });
      print('❌ Error loading notifications: $e');
    }
  }

  Future<void> _markAsRead(int notificationId, int index) async {
    if (authToken == null) return;

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/notifications/$notificationId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      print('📱 Mark as read response: ${response.statusCode}');

      if (response.statusCode == 200) {
        setState(() {
          final updatedNotification = NotificationUser(
            notificationId: notifications[index].notificationId,
            userId: notifications[index].userId,
            readAt: DateTime.now().toIso8601String(),
            notification: notifications[index].notification,
          );
          notifications[index] = updatedNotification;
        });

        print('✅ Notification marked as read');
      }
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  void _onNavItemTapped(int index) {
    if (index == _selectedIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Community()),
        );
        break;
      case 2:
        // Add your search/recipe page here
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfileRecipePage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF0D8B8B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Color(0xFF0D8B8B),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        // ← REMOVED: actions dengan Mark All Read button
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadNotifications,
            color: const Color(0xFF0D8B8B),
            child: _buildBody(),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              margin: const EdgeInsets.all(16),
              child: CustomNavbar(
                selectedIndex: _selectedIndex,
                onItemTapped: _onNavItemTapped,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0D8B8B)),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTokenAndNotifications,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D8B8B),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    if (notifications.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 100),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none,
                  color: Colors.grey,
                  size: 64,
                ),
                SizedBox(height: 16),
                Text(
                  'No notifications yet',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'You\'ll see notifications here when you get them',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Extra bottom padding for navbar
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _buildNotificationCard(notification, index);
      },
    );
  }

  Widget _buildNotificationCard(NotificationUser notification, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isRead 
            ? Colors.grey.shade50 
            : const Color(0xFFB2E4E4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead 
              ? Colors.grey.shade200 
              : const Color(0xFF0D8B8B).withOpacity(0.3),
        ),
      ),
      child: InkWell(
        onTap: () {
          if (!notification.isRead) {
            _markAsRead(notification.notificationId, index);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: notification.isRead 
                      ? Colors.grey.shade400 
                      : const Color(0xFF0D8B8B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getNotificationIcon(notification.notification.judul),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.notification.judul,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: notification.isRead 
                            ? FontWeight.normal 
                            : FontWeight.w600,
                        color: notification.isRead 
                            ? Colors.grey.shade600 
                            : const Color(0xFF0D8B8B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.notification.deskripsi,
                      style: TextStyle(
                        fontSize: 14,
                        color: notification.isRead 
                            ? Colors.grey.shade500 
                            : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDate(notification.notification.createdAt),
                          style: const TextStyle(
                            fontSize: 12, 
                            color: Colors.grey
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0D8B8B),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String title) {
    final titleLower = title.toLowerCase();
    if (titleLower.contains('recipe') || titleLower.contains('resep')) {
      return Icons.restaurant_menu;
    } else if (titleLower.contains('update') || titleLower.contains('fitur')) {
      return Icons.system_update;
    } else if (titleLower.contains('reminder') || titleLower.contains('coba')) {
      return Icons.access_time;
    } else if (titleLower.contains('follow')) {
      return Icons.person_add;
    } else if (titleLower.contains('like') || titleLower.contains('favorite')) {
      return Icons.favorite;
    } else if (titleLower.contains('selamat') || titleLower.contains('welcome')) {
      return Icons.waving_hand;
    } else if (titleLower.contains('event') || titleLower.contains('challenge')) {
      return Icons.emoji_events;
    } else if (titleLower.contains('trending')) {
      return Icons.trending_up;
    } else {
      return Icons.notifications;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} min ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return dateString;
    }
  }
}