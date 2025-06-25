import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/community.dart';
import 'dart:convert';
import '../profile/Profile.dart';
import '../search/Search.dart';
import '../profile/Following.dart';
import '../profile/Followers.dart';
import '../Main.dart';
import '../search/DetailMenu.dart';
import '../home/HomePage.dart';
import '../notification/Notification.dart';
import '../auth/Login.dart'; // Import login page

class Community extends StatelessWidget {
  const Community({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Recipe App',
      theme: ThemeData(
        primaryColor: const Color(0xFF2A9D8F),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2A9D8F),
          primary: const Color(0xFF2A9D8F),
        ),
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const CommunityScreen(),
    );
  }
}

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  int _selectedIndex = 1;
  bool isLoadingCommunities = true;
  bool isLoggedIn = false; // Check if user is logged in
  String? userToken; // Store user token

  List<Map<String, dynamic>> communities = [];

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _fetchCommunities();
  }

  // Check if user is logged in (implement according to your auth system)
  void _checkLoginStatus() {
    // Replace this with your actual login check logic
    // For example: check SharedPreferences for token
    setState(() {
      isLoggedIn = false; // Set to true if user is logged in
      userToken = null; // Set actual token if logged in
    });
  }

  Future<void> _fetchCommunities() async {
    setState(() {
      isLoadingCommunities = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/communities'),
        headers: {
          'Content-Type': 'application/json',
          // Add auth header if user is logged in
          if (isLoggedIn && userToken != null)
            'Authorization': 'Bearer $userToken',
        },
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📊 Parsed data: $data');

        // Handle different possible response structures
        List<dynamic>? communityList;
        
        // Try different possible paths for the communities data
        if (data is Map<String, dynamic>) {
          // Try: data.communities
          communityList = data['communities'] as List<dynamic>?;
          
          // Try: data.data.communities
          if (communityList == null && data['data'] != null) {
            final dataSection = data['data'] as Map<String, dynamic>?;
            communityList = dataSection?['communities'] as List<dynamic>?;
          }
          
          // Try: data.data (if communities is directly in data)
          if (communityList == null && data['data'] is List<dynamic>) {
            communityList = data['data'] as List<dynamic>?;
          }
        } else if (data is List<dynamic>) {
          // If response is directly an array
          communityList = data;
        }

        print('📋 Community list: $communityList');

        if (communityList != null && communityList.isNotEmpty) {
          setState(() {
            communities = List<Map<String, dynamic>>.from(
              communityList!.map((item) {
                // Handle different field names that might come from API
                final Map<String, dynamic> communityItem = item as Map<String, dynamic>;
                
                return {
                  'id': communityItem['id'] ?? communityItem['community_id'] ?? 0,
                  'nama': communityItem['nama'] ?? 
                         communityItem['name'] ?? 
                         communityItem['community_name'] ?? 
                         'Unknown Community',
                  'member_count': communityItem['member_count'] ?? 
                                 communityItem['members'] ?? 
                                 communityItem['total_members'] ?? 
                                 0,
                  'is_joined': communityItem['is_joined'] ?? 
                              communityItem['joined'] ?? 
                              false,
                };
              }),
            );
            print('✅ Communities loaded: ${communities.length}');
            communities.forEach((community) {
              print('  - ${community['nama']}: ${community['member_count']} members');
            });
          });
        } else {
          print('⚠️ No communities found in response');
          // Set empty list if no communities found
          setState(() {
            communities = [];
          });
        }
      } else {
        print('❌ Failed to load communities: ${response.statusCode}');
        print('❌ Error response: ${response.body}');
        throw Exception('Failed to load communities: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Error fetching communities: $e');
      
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load communities. Using default data.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      
      // Fallback to default communities for testing
      setState(() {
        communities = [
          {
            'id': 1,
            'nama': 'Breakfast',
            'member_count': 125,
            'is_joined': false,
          },
          {
            'id': 2,
            'nama': 'Lunch',
            'member_count': 98,
            'is_joined': false,
          },
          {
            'id': 3,
            'nama': 'Dinner',
            'member_count': 210,
            'is_joined': false,
          },
          {
            'id': 4,
            'nama': 'Dessert',
            'member_count': 165,
            'is_joined': false,
          },
          {
            'id': 5,
            'nama': 'Snack',
            'member_count': 87,
            'is_joined': false,
          },
          {
            'id': 6,
            'nama': 'Healthy Food',
            'member_count': 143,
            'is_joined': false,
          },
        ];
      });
    } finally {
      setState(() {
        isLoadingCommunities = false;
      });
    }
  }

  Future<void> _toggleJoinCommunity(int index) async {
    if (!isLoggedIn) {
      // Redirect to login page
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
      );

      // If user logged in successfully, refresh the communities
      if (result == true) {
        _checkLoginStatus();
        _fetchCommunities();
      }
      return;
    }

    final communityId = communities[index]['id'];
    final isCurrentlyJoined = communities[index]['is_joined'];
    final endpoint = isCurrentlyJoined ? 'leave' : 'join';

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/communities/$communityId/$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $userToken',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          communities[index]['is_joined'] = !isCurrentlyJoined;
          // Update member count
          if (isCurrentlyJoined) {
            communities[index]['member_count']--;
          } else {
            communities[index]['member_count']++;
          }
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isCurrentlyJoined
                ? 'Successfully left ${communities[index]['nama']}!'
                : 'Successfully joined ${communities[index]['nama']}!'),
            backgroundColor: Color(0xFF2A9D8F),
          ),
        );
      } else {
        throw Exception('Failed to ${endpoint} community');
      }
    } catch (e) {
      print('Error ${endpoint}ing community: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to ${endpoint} community. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
        break;
      case 1:
        // Already on Community page
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RecipePage()),
        );
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
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildHeader(context),
                    const SizedBox(height: 24),
                    _buildCommunityList(),
                    const SizedBox(height: 80), // Space for bottom navigation
                  ],
                ),
              ),
            ),
          ),
          // Custom Bottom Navigation
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 240,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.teal,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(4, (index) {
                    final icons = [
                      Icons.home_outlined,
                      Icons.chat_bubble_outline,
                      Icons.search,
                      Icons.person_outline,
                    ];

                    final isSelected = _selectedIndex == index;

                    return GestureDetector(
                      onTap: () => _onNavItemTapped(index),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: isSelected && index == 1
                            ? const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              )
                            : null,
                        child: Icon(icons[index], color: Colors.white),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF2A9D8F)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        Text(
          'Community',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2A9D8F),
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Color(0xFFA9D6DB),
              shape: BoxShape.circle,
            ),
            padding: EdgeInsets.all(8),
            child: Icon(
              Icons.notifications,
              color: Color(0xFF2A9D8F),
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommunityList() {
    if (isLoadingCommunities) {
      return Center(
        child: CircularProgressIndicator(
          color: Color(0xFF2A9D8F),
        ),
      );
    }

    if (communities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No communities available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Communities',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2A9D8F),
          ),
        ),
        SizedBox(height: 16),
        ListView.builder(
          itemCount: communities.length,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final community = communities[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildCommunityCard(community, index),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCommunityCard(Map<String, dynamic> community, int index) {
    final isJoined = community['is_joined'] as bool;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Community Icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Color(0xFF2A9D8F).withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(
              Icons.groups,
              color: Color(0xFF2A9D8F),
              size: 24,
            ),
          ),
          SizedBox(width: 16),

          // Community Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  community['nama'] ?? 'Unknown Community',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${community['member_count'] ?? 0} members',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Join/Leave Button
          GestureDetector(
            onTap: () => _toggleJoinCommunity(index),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isJoined ? Colors.grey[300] : Color(0xFF2A9D8F),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isJoined ? 'Joined' : 'Join',
                style: TextStyle(
                  color: isJoined ? Colors.grey[700] : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}