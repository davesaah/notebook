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
          Expanded(
            child: AspectRatio(
              aspectRatio: 100 / 140, // Maintains original notebook dimensions
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                    topLeft: Radius.circular(2),
                    bottomLeft: Radius.circular(2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(3, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 8,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 2,
                        color: Colors.black.withValues(alpha: 0.15),
                      ),
                    ),
                    Positioned(
                      right: 12,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 6,
                        color: Colors.black.withValues(alpha: 0.2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 24, 16),
                      child: Text(
                        title.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '($count)',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
