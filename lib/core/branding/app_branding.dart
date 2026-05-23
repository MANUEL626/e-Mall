import 'package:flutter/material.dart';

/// Logo principal e-Mall (PNG — même ressource que les icônes de lanceur).
class AppBranding {
  AppBranding._();

  static const String appName = 'e-Mall';
  static const String logoPngAsset = 'assets/image/emall-icon-orange.png';

  /// Image du logo ; [height] / [width] optionnels pour contraindre la taille.
  static Widget logoImage({
    double? height,
    double? width,
    BoxFit fit = BoxFit.contain,
    BorderRadius? borderRadius,
  }) {
    Widget img = Image.asset(
      logoPngAsset,
      height: height,
      width: width,
      fit: fit,
      filterQuality: FilterQuality.high,
      semanticLabel: '$appName logo',
      errorBuilder: (_, __, ___) => _LogoFallback(height: height, width: width),
    );
    if (borderRadius != null) {
      img = ClipRRect(borderRadius: borderRadius, child: img);
    }
    return img;
  }

  static Widget appIcon({
    double size = 40,
    BorderRadius? borderRadius,
  }) {
    return logoImage(
      width: size,
      height: size,
      fit: BoxFit.contain,
      borderRadius: borderRadius ?? BorderRadius.circular(size * 0.22),
    );
  }
}

class _LogoFallback extends StatelessWidget {
  const _LogoFallback({this.height, this.width});

  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final size = height ?? width ?? 40;
    return Container(
      height: height,
      width: width,
      constraints: BoxConstraints.tightFor(width: width ?? size, height: height ?? size),
      decoration: BoxDecoration(
        color: const Color(0xFFF26D21),
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      alignment: Alignment.center,
      child: Text(
        'e',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.62,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
