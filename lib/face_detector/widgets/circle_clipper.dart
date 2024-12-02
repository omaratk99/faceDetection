import 'package:flutter/material.dart';
class CircleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: 130,
      ));
    return path..fillType = PathFillType.evenOdd;
  }

  @override
  bool shouldReclip(CircleClipper oldClipper) => false;
}