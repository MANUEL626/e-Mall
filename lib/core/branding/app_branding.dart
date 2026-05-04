import 'package:flutter/material.dart';

/// Logo principal e-Mall (PNG — même ressource que les icônes de lanceur).
class AppBranding {
  AppBranding._();

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
    );
    if (borderRadius != null) {
      img = ClipRRect(borderRadius: borderRadius, child: img);
    }
    return img;
  }
}
