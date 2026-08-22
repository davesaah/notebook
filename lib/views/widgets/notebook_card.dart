import 'package:flutter/material.dart';

class NotebookCard extends StatelessWidget {
  final String title;
  final Color color;
  final int count;
  final VoidCallback? onTap;

  const NotebookCard({
    super.key,
    required this.title,
    required this.color,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fixed width with proportional height based on 100/140 ratio
          SizedBox(
            width: 140, // Scaled up width (Adjust this to scale the card up/down)
            child: AspectRatio(
              aspectRatio: 100 / 140,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                    topLeft: Radius.circular(3),
                    bottomLeft: Radius.circular(3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(4, 5),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Left spine line
                    Positioned(
                      left: 12,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 3,
                        color: Colors.black.withValues(alpha: 0.15),
                      ),
                    ),
                    // Right edge accent
                    Positioned(
                      right: 16,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 8,
                        color: Colors.black.withValues(alpha: 0.2),
                      ),
                    ),
                    // Title text with increased font size and padding
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 26, 30, 20),
                      child: Text(
                        title.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14, // Scaled up font size
                          letterSpacing: 0.6,
                          height: 1.2,
                        ),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '($count)',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 15, // Scaled up count label
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}