import 'package:flutter/material.dart';
import 'package:gym_reservation/responsive_helper.dart';

/// Farklı ekran boyutlarına göre ölçeklenen metin widget'ı
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final double minFontSize;
  final double maxFontSize;
  final bool scaleByWidth;

  const ResponsiveText(
    this.text, {
    Key? key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.minFontSize = 10.0,
    this.maxFontSize = 30.0,
    this.scaleByWidth = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Metin stili yok ise varsayılan stili kullan
    final defaultStyle = DefaultTextStyle.of(context).style;
    final effectiveStyle = style ?? defaultStyle;

    // Mevcut font boyutunu al
    final fontSize = effectiveStyle.fontSize ?? 14.0;

    // Ekran boyutuna göre ölçeklendirilmiş font boyutunu hesapla
    final double scaledFontSize = ResponsiveHelper.getAdaptiveFontSize(
      context,
      fontSize,
      minFontSize: minFontSize,
      maxFontSize: maxFontSize,
    );

    // Eğer yatay ölçeklendirme isteniyorsa genişliğe göre ölçeklendir
    final double finalFontSize =
        scaleByWidth
            ? scaledFontSize *
                (MediaQuery.of(context).size.width / 375.0).clamp(0.8, 1.2)
            : scaledFontSize;

    return MediaQuery(
      // Override MediaQuery verileri
      data: MediaQuery.of(context).copyWith(
        textScaleFactor: 1.0, // Kendi ölçeklendirmemizi kullanıyoruz
      ),
      child: Text(
        text,
        style: effectiveStyle.copyWith(fontSize: finalFontSize),
        textAlign: textAlign,
        overflow: overflow,
        maxLines: maxLines,
      ),
    );
  }
}

/// Responsive bir başlık metni
class ResponsiveHeading extends StatelessWidget {
  final String text;
  final Color? color;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final double level;

  const ResponsiveHeading(
    this.text, {
    Key? key,
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.level = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Başlık seviyesine göre font boyutunu belirle (1: En büyük, 6: En küçük)
    double baseFontSize;
    FontWeight fontWeight;

    switch (level.round().clamp(1, 6)) {
      case 1:
        baseFontSize = 28.0;
        fontWeight = FontWeight.bold;
        break;
      case 2:
        baseFontSize = 24.0;
        fontWeight = FontWeight.bold;
        break;
      case 3:
        baseFontSize = 22.0;
        fontWeight = FontWeight.bold;
        break;
      case 4:
        baseFontSize = 20.0;
        fontWeight = FontWeight.w600;
        break;
      case 5:
        baseFontSize = 18.0;
        fontWeight = FontWeight.w600;
        break;
      case 6:
        baseFontSize = 16.0;
        fontWeight = FontWeight.w500;
        break;
      default:
        baseFontSize = 24.0;
        fontWeight = FontWeight.bold;
    }

    // Yatay modda daha küçük metin
    if (ResponsiveHelper.isLandscape(context)) {
      baseFontSize *= 0.8;
    }

    return ResponsiveText(
      text,
      style: TextStyle(
        fontSize: baseFontSize,
        fontWeight: fontWeight,
        color: color ?? Colors.white,
      ),
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      minFontSize: baseFontSize * 0.7,
      maxFontSize: baseFontSize * 1.3,
    );
  }
}

/// Responsive bir alt başlık
class ResponsiveSubtitle extends StatelessWidget {
  final String text;
  final Color? color;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;

  const ResponsiveSubtitle(
    this.text, {
    Key? key,
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveText(
      text,
      style: TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.w500,
        color: color ?? const Color(0xFFBFC6D2),
      ),
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      minFontSize: 12.0,
      maxFontSize: 20.0,
    );
  }
}

/// Responsive bir etiket metni
class ResponsiveLabel extends StatelessWidget {
  final String text;
  final Color? color;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;

  const ResponsiveLabel(
    this.text, {
    Key? key,
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveText(
      text,
      style: TextStyle(
        fontSize: 12.0,
        fontWeight: FontWeight.normal,
        color: color ?? const Color(0xFFBFC6D2),
      ),
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      minFontSize: 10.0,
      maxFontSize: 16.0,
    );
  }
}
