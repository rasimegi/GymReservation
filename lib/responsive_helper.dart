import 'package:flutter/material.dart';

/// Uygulamayı responsive yapmak için kullanılan yardımcı sınıf
/// Farklı cihaz boyutlarına göre ölçeklendirme ve boyutlandırma sağlar
class ResponsiveHelper {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 768;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 768 &&
      MediaQuery.of(context).size.width < 1200;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;

  /// Cihazın yatay modda olup olmadığını kontrol eder
  static bool isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  static double getScreenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double getScreenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static double getPaddingScale(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 400) return 0.8; // Küçük telefonlar için
    if (width < 768) return 1.0; // Normal telefonlar için
    if (width < 1200) return 1.2; // Tabletler için
    return 1.5; // Masaüstü için
  }

  static double getFontScale(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 400) return 0.8; // Küçük telefonlar için
    if (width < 768) return 1.0; // Normal telefonlar için
    if (width < 1200) return 1.1; // Tabletler için
    return 1.2; // Masaüstü için
  }

  /// Font boyutunu ekran boyutuna göre uyarlar
  static double getAdaptiveFontSize(
    BuildContext context,
    double fontSize, {
    double minFontSize = 10.0,
    double maxFontSize = 30.0,
  }) {
    final fontScale = getFontScale(context);
    final screenType = getScreenType(context);
    final isLandscape = ResponsiveHelper.isLandscape(context);

    // Ekran tipine göre ek ölçeklendirme faktörü
    double screenTypeFactor;
    switch (screenType) {
      case ScreenType.xSmall:
        screenTypeFactor = 0.85;
        break;
      case ScreenType.small:
        screenTypeFactor = 0.9;
        break;
      case ScreenType.medium:
        screenTypeFactor = 1.0;
        break;
      case ScreenType.large:
        screenTypeFactor = 1.1;
        break;
      case ScreenType.xLarge:
        screenTypeFactor = 1.2;
        break;
    }

    // Yatay mod için ek ölçeklendirme
    if (isLandscape) {
      screenTypeFactor *= 0.9;
    }

    // Font boyutunu ölçeklendir
    double scaledSize = fontSize * fontScale * screenTypeFactor;

    // Min/max sınırları uygula
    return scaledSize.clamp(minFontSize, maxFontSize);
  }

  static EdgeInsets getScreenPadding(BuildContext context) {
    final scale = getPaddingScale(context);
    return EdgeInsets.all(16.0 * scale);
  }

  /// Ekran tipini belirler
  static ScreenType getScreenType(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 360) return ScreenType.xSmall; // Çok küçük telefonlar
    if (width < 600) return ScreenType.small; // Telefonlar
    if (width < 900)
      return ScreenType.medium; // Büyük telefonlar / küçük tabletler
    if (width < 1200) return ScreenType.large; // Tabletler
    return ScreenType.xLarge; // Masaüstü
  }

  /// Değeri ekran boyutuna göre ölçeklendirir
  static double getDynamicValue(
    BuildContext context,
    double value, {
    double xSmallScale = 0.8,
    double smallScale = 0.9,
    double mediumScale = 1.0,
    double largeScale = 1.2,
    double xLargeScale = 1.5,
  }) {
    final screenType = getScreenType(context);

    switch (screenType) {
      case ScreenType.xSmall:
        return value * xSmallScale;
      case ScreenType.small:
        return value * smallScale;
      case ScreenType.medium:
        return value * mediumScale;
      case ScreenType.large:
        return value * largeScale;
      case ScreenType.xLarge:
        return value * xLargeScale;
    }
  }

  /// Ekran boyutuna göre uyarlanmış padding değeri döndürür
  static EdgeInsets getAdaptivePadding(
    BuildContext context, {
    double basePadding = 16.0,
    double horizontalScale = 1.0,
    double verticalScale = 1.0,
  }) {
    final screenType = getScreenType(context);
    double scaleFactor;

    switch (screenType) {
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
        scaleFactor = 1.2;
        break;
      case ScreenType.xLarge:
        scaleFactor = 1.5;
        break;
    }

    return EdgeInsets.symmetric(
      horizontal: basePadding * scaleFactor * horizontalScale,
      vertical: basePadding * scaleFactor * verticalScale,
    );
  }

  static Widget getResponsiveLayout({
    required BuildContext context,
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    if (isDesktop(context) && desktop != null) {
      return desktop;
    } else if (isTablet(context) && tablet != null) {
      return tablet;
    } else {
      return mobile;
    }
  }
}

/// Ekran tipleri
enum ScreenType { xSmall, small, medium, large, xLarge }
