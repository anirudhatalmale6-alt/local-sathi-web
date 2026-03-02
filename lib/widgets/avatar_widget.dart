import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AvatarWidget extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double size;
  final Color? backgroundColor;
  final List<Color>? gradientColors;

  const AvatarWidget({
    super.key,
    this.photoUrl,
    required this.name,
    this.size = 48,
    this.backgroundColor,
    this.gradientColors,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Color get _defaultColor {
    final colors = [
      const Color(0xFF1565C0),
      const Color(0xFFE65100),
      const Color(0xFF2E7D32),
      const Color(0xFF6A1B9A),
      const Color(0xFFC62828),
      const Color(0xFF00695C),
      const Color(0xFF4527A0),
      const Color(0xFFBF360C),
    ];
    final hash = name.codeUnits.fold(0, (prev, el) => prev + el);
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: CachedNetworkImage(
          imageUrl: photoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => _placeholderWidget(),
          errorWidget: (_, __, ___) => _placeholderWidget(),
        ),
      );
    }
    return _placeholderWidget();
  }

  Widget _placeholderWidget() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradientColors != null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors!,
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  backgroundColor ?? _defaultColor,
                  (backgroundColor ?? _defaultColor).withOpacity(0.7),
                ],
              ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.36,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
