import 'package:flutter/material.dart';

// Import all the required pages
import 'auth/Login.dart';
import 'auth/Signup.dart';
import 'auth/CreateProfile.dart';
import 'auth/CreatePassword.dart';
import 'home/HomePage.dart';
import 'community/Community.dart';
import 'search/Search.dart';
import 'search/SortBy.dart';
import 'search/DetailMenu.dart';
import 'profile/Profile.dart';
import 'myresep/EditRecipe.dart';
import 'trending_resep/TrendingResep.dart';
import 'reviews/AddReviews.dart';
import 'reviews/Reviews.dart';
import 'notification/Notification.dart';

class MainMenu extends StatelessWidget {
  const MainMenu({Key? key}) : super(key: key);

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _navigateTo(BuildContext context, Widget page) {
    try {
      Navigator.push(context, MaterialPageRoute(builder: (context) => page));
    } catch (e) {
      _showErrorSnackbar(context, 'Navigation error: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define menu items with icons, titles, and navigation targets
    final List<Map<String, dynamic>> menuItems = [
      {
        'icon': Icons.home,
        'title': 'Home',
        'color': Colors.teal,
        'onTap': () {
          try {
            _navigateTo(context, const HomePage());
          } catch (e) {
            _showErrorSnackbar(context, 'Could not navigate to Home');
          }
        },
      },
      {
        'icon': Icons.search,
        'title': 'Search',
        'color': Colors.blue,
        'onTap': () {
          try {
            _navigateTo(context, const RecipePage());
          } catch (e) {
            _showErrorSnackbar(context, 'Could not navigate to Search');
          }
        },
      },
      {
        'icon': Icons.people,
        'title': 'Community',
        'color': Colors.green,
        'onTap': () {
          try {
            _navigateTo(context, const Community());
          } catch (e) {
            _showErrorSnackbar(context, 'Could not navigate to Community');
          }
        },
      },
      {
        'icon': Icons.person,
        'title': 'Profile',
        'color': Colors.orange,
        'onTap': () {
          try {
            _navigateTo(context, const ProfileRecipePage());
          } catch (e) {
            _showErrorSnackbar(context, 'Could not navigate to Profile');
          }
        },
      },
      {
        'icon': Icons.sort,
        'title': 'Sort Recipes',
        'color': Colors.purple,
        'onTap': () {
          try {
            _navigateTo(context, const FilterPage());
          } catch (e) {
            _showErrorSnackbar(context, 'Could not navigate to Sort Recipes');
          }
        },
      },
      {
        'icon': Icons.trending_up,
        'title': 'Trending',
        'color': Colors.red,
        'onTap': () {
          try {
            _navigateTo(context, const TrendingResepPage());
          } catch (e) {
            _showErrorSnackbar(context, 'Could not navigate to Trending');
          }
        },
      },
      {
        'icon': Icons.add_circle,
        'title': 'Upload Recipe',
        'color': Colors.pink,
        'onTap': () {
          try {
            _navigateTo(context, const EditRecipePage());
          } catch (e) {
            _showErrorSnackbar(context, 'Could not navigate to Upload Recipe');
          }
        },
      },
      {
        'icon': Icons.login,
        'title': 'Login',
        'color': Colors.indigo,
        'onTap': () {
          try {
            _navigateTo(context, const Login());
          } catch (e) {
            _showErrorSnackbar(context, 'Could not navigate to Login');
          }
        },
      },
      {
        'icon': Icons.app_registration,
        'title': 'Sign Up',
        'color': Colors.cyan,
        'onTap': () {
          try {
            _navigateTo(context, const SignUp());
          } catch (e) {
            _showErrorSnackbar(context, 'Could not navigate to Sign Up');
          }
        },
      },
      {
        'icon': Icons.person_add, // Ikon untuk membuat profil baru
        'title': 'Create New Profile',
        'color': Colors.indigo,
        'onTap': () {
          try {
            _navigateTo(
              context,
              const CreateProfile(),
            ); // Ganti dengan halaman CreateProfile
          } catch (e) {
            _showErrorSnackbar(
              context,
              'Could not navigate to Create New Profile',
            );
          }
        },
      },
      {
        'icon': Icons.lock_open, // Ikon untuk membuat password baru
        'title': 'Create New Password',
        'color': Colors.indigo,
        'onTap': () {
          try {
            _navigateTo(
              context,
              const CreatePasswordPage(),
            ); // Ganti dengan halaman CreatePassword
          } catch (e) {
            _showErrorSnackbar(
              context,
              'Could not navigate to Create New Password',
            );
          }
        },
      },
      {
        'icon': Icons.reviews,
        'title': 'Reviews',
        'color': Colors.amber,
        'onTap': () {
          try {
            _navigateTo(context, Reviews(recipeId: 1));
          } catch (e) {
            _showErrorSnackbar(context, 'Could not navigate to Reviews');
          }
        },
      },
      {
        'icon': Icons.rate_review,
        'title': 'Add Review',
        'color': Colors.brown,
        'onTap': () {
          try {
            _navigateTo(context, const ReviewFormPage());
          } catch (e) {
            _showErrorSnackbar(context, 'Could not navigate to Add Review');
          }
        },
      },
      {
        'icon': Icons.restaurant_menu,
        'title': 'Recipe Details',
        'color': Colors.deepOrange,
        'onTap': () {
          try {
            _navigateTo(context, const DetailMenu(recipeId: 1));
          } catch (e) {
            _showErrorSnackbar(context, 'Could not navigate to Recipe Details');
          }
        },
      },
      {
        'icon': Icons.notifications_none, // Ikon notifikasi kosong
        'title': 'Notification',
        'color': Colors.amber, // Warna yang cocok untuk notifikasi
        'onTap': () {
          try {
            _navigateTo(
              context,
              const NotificationsScreen(),
            ); // Ganti dengan halaman notifikasi kamu
          } catch (e) {
            _showErrorSnackbar(context, 'Could not navigate to Notification');
          }
        },
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe App'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  return _buildMenuItem(
                    context,
                    menuItems[index]['icon'],
                    menuItems[index]['title'],
                    menuItems[index]['color'],
                    menuItems[index]['onTap'],
                  );
                },
              ),
            ),
          ),
          // The +1 additional button at the bottom
          // Padding(
          //   padding: const EdgeInsets.only(bottom: 24.0, left: 16.0, right: 16.0),
          //   child: SizedBox(
          //     width: double.infinity,
          //     height: 60,
          //     child: ElevatedButton.icon(
          //       onPressed: () {
          //         // You can add a settings page later
          //         ScaffoldMessenger.of(context).showSnackBar(
          //           const SnackBar(
          //             content: Text('Settings page coming soon'),
          //           ),
          //         );
          //       },
          //       icon: const Icon(Icons.settings),
          //       label: const Text('Settings', style: TextStyle(fontSize: 18)),
          //       style: ElevatedButton.styleFrom(
          //         backgroundColor: Colors.grey[800],
          //         foregroundColor: Colors.white,
          //         shape: RoundedRectangleBorder(
          //           borderRadius: BorderRadius.circular(12),
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
