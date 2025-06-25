import 'package:flutter/material.dart';

class CustomNavbar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomNavbar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // List icon untuk navbar
    final icons = [
      Icons.home_outlined,
      Icons.chat_bubble_outline,
      Icons.search,
      Icons.person_outline,
    ];

    return Positioned(
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
            children: List.generate(icons.length, (index) {
              final isSelected = selectedIndex == index;

              return GestureDetector(
                onTap: () => onItemTapped(index), // Panggil fungsi saat tap
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: isSelected
                      ? const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.white, width: 2),
                          ),
                        )
                      : null,
                  child: Icon(
                    icons[index],
                    color: Colors.white,
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}