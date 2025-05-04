import 'package:flutter/material.dart';
import 'package:gym_reservation/responsive_helper.dart';

/// Responsive bir widget wrapper'ı
/// İçeriğini ekran boyutuna göre ayarlar
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final bool adjustHeightForKeyboard;
  final double maxWidth;
  final EdgeInsets padding;

  const ResponsiveWrapper({
    Key? key,
    required this.child,
    this.adjustHeightForKeyboard = true,
    this.maxWidth = 600,
    this.padding = EdgeInsets.zero,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isKeyboardOpen = mediaQuery.viewInsets.bottom > 0;
    final screenSize = mediaQuery.size;
    final isLandscape = ResponsiveHelper.isLandscape(context);

    // Klavye açıkken yüksekliği ayarla
    double effectiveHeight = screenSize.height;
    if (adjustHeightForKeyboard && isKeyboardOpen) {
      effectiveHeight -= mediaQuery.viewInsets.bottom;
    }

    // Yatay modda maksimum genişliği sınırla
    double effectiveWidth = screenSize.width;
    if (isLandscape && effectiveWidth > maxWidth) {
      effectiveWidth = maxWidth;
    }

    // Padding'i ekran boyutuna göre ayarla
    final adaptivePadding = ResponsiveHelper.getAdaptivePadding(
      context,
      basePadding: padding.horizontal / 2,
      horizontalScale: isLandscape ? 1.5 : 1.0,
      verticalScale: isLandscape ? 0.8 : 1.0,
    );

    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: effectiveWidth,
          minHeight: effectiveHeight - mediaQuery.padding.vertical,
        ),
        padding: adaptivePadding,
        child: child,
      ),
    );
  }
}

/// Responsive tek bir satır (Row)
class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double spacing;

  const ResponsiveRow({
    Key? key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.spacing = 16.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isLandscape = ResponsiveHelper.isLandscape(context);
    final adaptiveSpacing = ResponsiveHelper.getDynamicValue(
      context,
      spacing,
      smallScale: 0.75,
      xLargeScale: 1.5,
    );

    // Yatay modda bir Row, dikey modda bir Column
    if (isLandscape || MediaQuery.of(context).size.width >= 600) {
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: _addSpacing(context, adaptiveSpacing, isLandscape),
      );
    } else {
      return Column(
        mainAxisAlignment: _convertMainAxisAlignment(),
        crossAxisAlignment: _convertCrossAxisAlignment(),
        children: _addSpacing(context, adaptiveSpacing, isLandscape),
      );
    }
  }

  // Row ve Column arasında geçiş yaparken hizalamaları dönüştür
  MainAxisAlignment _convertMainAxisAlignment() {
    switch (crossAxisAlignment) {
      case CrossAxisAlignment.start:
        return MainAxisAlignment.start;
      case CrossAxisAlignment.end:
        return MainAxisAlignment.end;
      case CrossAxisAlignment.center:
        return MainAxisAlignment.center;
      default:
        return MainAxisAlignment.start;
    }
  }

  CrossAxisAlignment _convertCrossAxisAlignment() {
    switch (mainAxisAlignment) {
      case MainAxisAlignment.start:
        return CrossAxisAlignment.start;
      case MainAxisAlignment.end:
        return CrossAxisAlignment.end;
      case MainAxisAlignment.center:
        return CrossAxisAlignment.center;
      default:
        return CrossAxisAlignment.center;
    }
  }

  // Child'lar arasına boşluk ekle
  List<Widget> _addSpacing(
    BuildContext context,
    double space,
    bool isLandscape,
  ) {
    final spacedChildren = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      spacedChildren.add(children[i]);
      if (i < children.length - 1) {
        if (isLandscape) {
          spacedChildren.add(SizedBox(width: space));
        } else {
          spacedChildren.add(SizedBox(height: space));
        }
      }
    }
    return spacedChildren;
  }
}

/// Responsive bir container
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final Decoration? decoration;

  const ResponsiveContainer({
    Key? key,
    required this.child,
    this.width = double.infinity,
    this.height = double.infinity,
    this.padding = EdgeInsets.zero,
    this.margin = EdgeInsets.zero,
    this.decoration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isLandscape = ResponsiveHelper.isLandscape(context);
    final screenType = ResponsiveHelper.getScreenType(context);

    // Ekran boyutuna göre padding ve margin hesapla
    final adaptivePadding = EdgeInsets.only(
      left: ResponsiveHelper.getDynamicValue(context, padding.left),
      right: ResponsiveHelper.getDynamicValue(context, padding.right),
      top:
          ResponsiveHelper.getDynamicValue(context, padding.top) *
          (isLandscape ? 0.7 : 1.0),
      bottom:
          ResponsiveHelper.getDynamicValue(context, padding.bottom) *
          (isLandscape ? 0.7 : 1.0),
    );

    final adaptiveMargin = EdgeInsets.only(
      left: ResponsiveHelper.getDynamicValue(context, margin.left),
      right: ResponsiveHelper.getDynamicValue(context, margin.right),
      top:
          ResponsiveHelper.getDynamicValue(context, margin.top) *
          (isLandscape ? 0.7 : 1.0),
      bottom:
          ResponsiveHelper.getDynamicValue(context, margin.bottom) *
          (isLandscape ? 0.7 : 1.0),
    );

    // Boyutları hesapla
    double adaptiveWidth = width;
    double adaptiveHeight = height;

    if (isLandscape) {
      // Yatay modda boyutları ayarla
      if (width != double.infinity) {
        adaptiveWidth = width * 0.8;
      }
      if (height != double.infinity) {
        adaptiveHeight = height * 0.7;
      }
    } else {
      // Dikey modda boyutları ayarla
      switch (screenType) {
        case ScreenType.xSmall:
          if (width != double.infinity) adaptiveWidth = width * 0.8;
          if (height != double.infinity) adaptiveHeight = height * 0.8;
          break;
        case ScreenType.small:
          if (width != double.infinity) adaptiveWidth = width * 0.9;
          if (height != double.infinity) adaptiveHeight = height * 0.9;
          break;
        case ScreenType.medium:
          // Varsayılan boyutlar
          break;
        case ScreenType.large:
          if (width != double.infinity) adaptiveWidth = width * 1.1;
          if (height != double.infinity) adaptiveHeight = height * 1.1;
          break;
        case ScreenType.xLarge:
          if (width != double.infinity) adaptiveWidth = width * 1.2;
          if (height != double.infinity) adaptiveHeight = height * 1.2;
          break;
      }
    }

    return Container(
      width: adaptiveWidth,
      height: adaptiveHeight,
      padding: adaptivePadding,
      margin: adaptiveMargin,
      decoration: decoration,
      child: child,
    );
  }
}
