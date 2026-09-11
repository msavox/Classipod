import 'package:flutter/cupertino.dart';

/// Darkens the four edges of the device body, so the frame reads as curving
/// away from the light rather than as a flat rectangle.
///
/// Sized by its parent, which is why it is painted across whatever area
/// actually carries the device background: the whole screen when the unused
/// area keeps the wallpaper, the frame alone otherwise.
class DeviceFrameEdgeShadows extends StatelessWidget {
  const DeviceFrameEdgeShadows({super.key});

  static const double _thickness = 20;
  static const DecoratedBox _edge = DecoratedBox(
    decoration: BoxDecoration(
      boxShadow: [BoxShadow(blurRadius: 100, spreadRadius: 1)],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return const Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SizedBox(height: _thickness, child: _edge),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SizedBox(height: _thickness, child: _edge),
        ),
        Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          child: SizedBox(width: _thickness, child: _edge),
        ),
        Positioned(
          top: 0,
          bottom: 0,
          right: 0,
          child: SizedBox(width: _thickness, child: _edge),
        ),
      ],
    );
  }
}
