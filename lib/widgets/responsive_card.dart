import 'package:flutter/material.dart';
import 'package:gym_reservation/responsive_helper.dart';
import 'package:gym_reservation/widgets/responsive_text.dart';

/// Farklı ekran boyutlarına göre ayarlanan responsive kart widget'ı
class ResponsiveCard extends StatelessWidget {
  final Widget? child;
  final double? width;
  final double? height;
  final Color color;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final GestureTapCallback? onTap;

  const ResponsiveCard({
    Key? key,
    this.child,
    this.width,
    this.height,
    this.color = const Color(0xFF1C1F26),
    this.padding = const EdgeInsets.all(16.0),
    this.margin = EdgeInsets.zero,
    this.borderRadius,
    this.boxShadow,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isLandscape = ResponsiveHelper.isLandscape(context);
    final screenSize = MediaQuery.of(context).size;
    final screenType = ResponsiveHelper.getScreenType(context);

    // Varsayılan değerler
    double effectiveWidth = width ?? double.infinity;
    double effectiveHeight = height ?? (isLandscape ? 90 : 105);

    // Ekran boyutuna göre ayarla
    if (width != null && width != double.infinity) {
      if (isLandscape) {
        effectiveWidth = width! * (screenSize.width / 800.0).clamp(0.7, 1.0);
      } else {
        switch (screenType) {
          case ScreenType.xSmall:
            effectiveWidth = width! * 0.85;
            break;
          case ScreenType.small:
            effectiveWidth = width! * 0.9;
            break;
          case ScreenType.medium:
            // Varsayılan boyut
            break;
          case ScreenType.large:
            effectiveWidth = width! * 1.1;
            break;
          case ScreenType.xLarge:
            effectiveWidth = width! * 1.2;
            break;
        }
      }
    }

    if (height != null && height != double.infinity) {
      if (isLandscape) {
        effectiveHeight = height! * 0.8; // Yatay modda daha kısa
      } else {
        switch (screenType) {
          case ScreenType.xSmall:
            effectiveHeight = height! * 0.85;
            break;
          case ScreenType.small:
            effectiveHeight = height! * 0.9;
            break;
          case ScreenType.medium:
            // Varsayılan boyut
            break;
          case ScreenType.large:
            effectiveHeight = height! * 1.1;
            break;
          case ScreenType.xLarge:
            effectiveHeight = height! * 1.2;
            break;
        }
      }
    }

    // Padding'i ekran boyutuna göre ayarla
    final adaptivePadding = EdgeInsets.only(
      left: ResponsiveHelper.getDynamicValue(context, padding.left),
      right: ResponsiveHelper.getDynamicValue(context, padding.right),
      top: ResponsiveHelper.getDynamicValue(context, padding.top),
      bottom: ResponsiveHelper.getDynamicValue(context, padding.bottom),
    );

    final adaptiveMargin = EdgeInsets.only(
      left: ResponsiveHelper.getDynamicValue(context, margin.left),
      right: ResponsiveHelper.getDynamicValue(context, margin.right),
      top: ResponsiveHelper.getDynamicValue(context, margin.top),
      bottom: ResponsiveHelper.getDynamicValue(context, margin.bottom),
    );

    final defaultBorderRadius = BorderRadius.circular(isLandscape ? 12 : 16);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: effectiveWidth,
        height: effectiveHeight,
        padding: adaptivePadding,
        margin: adaptiveMargin,
        decoration: BoxDecoration(
          color: color,
          borderRadius: borderRadius ?? defaultBorderRadius,
          boxShadow:
              boxShadow ??
              [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
        ),
        child: child,
      ),
    );
  }
}

/// İstatistik kartı - Sayı ve etiket gösteren
class ResponsiveStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final Color backgroundColor;
  final GestureTapCallback? onTap;

  const ResponsiveStatCard({
    Key? key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.iconColor,
    this.backgroundColor = const Color(0xFF1C1F26),
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? Colors.white.withOpacity(0.8);

    return ResponsiveCard(
      color: backgroundColor,
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: effectiveIconColor,
                    size: ResponsiveHelper.getDynamicValue(context, 20),
                  ),
                  SizedBox(width: ResponsiveHelper.getDynamicValue(context, 8)),
                  ResponsiveText(
                    title,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              onTap != null
                  ? Icon(
                    Icons.chevron_right,
                    color: Colors.white.withOpacity(0.8),
                    size: ResponsiveHelper.getDynamicValue(context, 20),
                  )
                  : Container(),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              ResponsiveText(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: ResponsiveHelper.getDynamicValue(context, 8)),
              if (subtitle != null)
                ResponsiveText(
                  subtitle!,
                  style: const TextStyle(
                    color: Color(0xFFBFC6D2),
                    fontSize: 16,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Başlık metinli responsive kart
class ResponsiveTitleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color titleColor;
  final EdgeInsets? padding;
  final double? height;

  const ResponsiveTitleCard({
    Key? key,
    required this.title,
    required this.subtitle,
    this.titleColor = Colors.red,
    this.padding,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? const EdgeInsets.all(16);

    return ResponsiveCard(
      height: height,
      padding: effectivePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ResponsiveText(
            title,
            style: TextStyle(
              color: titleColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getDynamicValue(context, 8)),
          ResponsiveText(
            subtitle,
            style: const TextStyle(color: Color(0xFFBFC6D2), fontSize: 14),
          ),
        ],
      ),
    );
  }
}
