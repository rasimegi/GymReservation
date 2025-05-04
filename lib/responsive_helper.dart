import 'package:flutter/material.dart';

/// Uygulamayı responsive yapmak için kullanılan yardımcı sınıf
/// Farklı cihaz boyutlarına göre ölçeklendirme ve boyutlandırma sağlar
class ResponsiveHelper {
  static const double _smallScreenBreakpoint = 320.0;
  static const double _mediumScreenBreakpoint = 480.0;
  static const double _largeScreenBreakpoint = 768.0;
  static const double _xLargeScreenBreakpoint = 1024.0;

  /// Cihaz boyutuna göre ekran tipini belirler
  static ScreenType getScreenType(BuildContext context) {
    final double deviceWidth = MediaQuery.of(context).size.width;
    if (deviceWidth < _smallScreenBreakpoint) {
      return ScreenType.xSmall;
    } else if (deviceWidth < _mediumScreenBreakpoint) {
      return ScreenType.small;
    } else if (deviceWidth < _largeScreenBreakpoint) {
      return ScreenType.medium;
    } else if (deviceWidth < _xLargeScreenBreakpoint) {
      return ScreenType.large;
    } else {
      return ScreenType.xLarge;
    }
  }

  /// Cihaz yönünü belirler
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Ekran boyutuna göre dinamik bir değer döndürür
  /// baseValue: temel değer
  /// scaleFactor: ölçek faktörü (yüzde olarak)
  static double getDynamicValue(
    BuildContext context,
    double baseValue, {
    double xSmallScale = 0.8,
    double smallScale = 0.9,
    double mediumScale = 1.0,
    double largeScale = 1.1,
    double xLargeScale = 1.2,
  }) {
    switch (getScreenType(context)) {
      case ScreenType.xSmall:
        return baseValue * xSmallScale;
      case ScreenType.small:
        return baseValue * smallScale;
      case ScreenType.medium:
        return baseValue * mediumScale;
      case ScreenType.large:
        return baseValue * largeScale;
      case ScreenType.xLarge:
        return baseValue * xLargeScale;
    }
  }

  /// Ekran boyutuna göre dinamik bir font boyutu döndürür
  static double getAdaptiveFontSize(
    BuildContext context,
    double baseFontSize, {
    double minFontSize = 12,
    double maxFontSize = 32,
  }) {
    double scaleFactor;
    switch (getScreenType(context)) {
      case ScreenType.xSmall:
        scaleFactor = 0.8;
        break;
      case ScreenType.small:
        scaleFactor = 0.9;
        break;
      case ScreenType.medium:
        scaleFactor = 1.0;
        break;
      case ScreenType.large:
        scaleFactor = 1.1;
        break;
      case ScreenType.xLarge:
        scaleFactor = 1.2;
        break;
    }

    final double adaptiveFontSize = baseFontSize * scaleFactor;
    return adaptiveFontSize.clamp(minFontSize, maxFontSize);
  }

  /// Ekran boyutuna göre dinamik bir padding değeri döndürür
  static EdgeInsets getAdaptivePadding(
    BuildContext context, {
    double basePadding = 16.0,
    double horizontalScale = 1.0,
    double verticalScale = 1.0,
  }) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double scaleFactor = (screenWidth / 375.0).clamp(0.8, 1.5);

    return EdgeInsets.symmetric(
      horizontal: basePadding * scaleFactor * horizontalScale,
      vertical: basePadding * scaleFactor * verticalScale,
    );
  }

  /// Yatay modda ekranın içeriğini düzenler
  static double getLandscapeAdjustment(BuildContext context, double value) {
    if (isLandscape(context)) {
      return value * 0.7; // Yatay modda daha küçük değerler
    }
    return value;
  }
}

/// Ekran tipleri
enum ScreenType { xSmall, small, medium, large, xLarge }
