import 'package:flutter/material.dart';

@immutable
class DotIconWidget extends StatelessWidget {
  const DotIconWidget({
    super.key,
    required this.active,
    required this.color,
    required this.width,
    required this.height,
  });

  final bool active;
  final Color color;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: AnimatedContainer(
        duration: Duration(milliseconds: active ? 50 : 0),
        margin: const EdgeInsets.symmetric(horizontal: 5.0),
        width: width,
        height: height,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? color : Colors.transparent,
          border: Border.all(
            color: active ? Colors.transparent : color,
          ),
          boxShadow: [
            if (active)
              BoxShadow(
                color: color.withOpacity(0.72),
                blurRadius: 4.0,
                spreadRadius: 1.0,
              ),
          ],
        ),
      ),
    );
  }
}
