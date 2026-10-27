import 'package:flutter/material.dart';

Widget fakeGlass({
  required Widget child,
  double radius = 18,
  double opacity = 0.18,
  double borderOpacity = 0.30,
  Color color = Colors.white,
}) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      color: color.withOpacity(opacity),
      border: Border.all(
        color: color.withOpacity(borderOpacity),
        width: 1.4,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.07),
          blurRadius: 18,
          offset: const Offset(0, 6),
        )
      ],
    ),
    child: child,
  );
}
