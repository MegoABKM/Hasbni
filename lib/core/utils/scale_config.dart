import 'dart:math';
import 'package:flutter/material.dart';

class ScaleConfig {
  final double referenceWidth;
  final double referenceHeight;
  final double referenceDPI;
  final double screenWidth;
  final double screenHeight;
  final double scaleWidth;
  final double scaleHeight;
  final double textScaleFactor;
  final Orientation orientation;
  final double devicePixelRatio;
  final double globalPixelTextAdjustment;

  // You might want to adjust this for testing if fonts are becoming too small
  static const double _minAbsFontSize = 6.0;
  // To make it easier to see changes during testing, let's use a more aggressive default here.
  // REMEMBER TO CHANGE THIS IN YOUR ACTUAL ScaleConfig() call below for permanent effect.
  // ignore: unused_field
  static const double _defaultTestAdjustment =
      0.0; // Set to -5.0 for aggressive testing if needed IN THE FACTORY

  ScaleConfig._({
    required this.referenceWidth,
    required this.referenceHeight,
    required this.referenceDPI,
    required this.screenWidth,
    required this.screenHeight,
    required this.scaleWidth,
    required this.scaleHeight,
    required this.textScaleFactor,
    required this.orientation,
    required this.devicePixelRatio,
    required this.globalPixelTextAdjustment,
  });

  factory ScaleConfig(
    BuildContext context, {
    double refWidth = 375,
    double refHeight = 812,
    double refDPI = 326,
    // ***** THIS IS THE IMPORTANT PART FOR YOUR GOAL *****
    // ***** SET THIS TO -2.0 (or -5.0 for more noticeable testing) *****
    double globalPixelTextAdjustment = -2.0, // Example: -2.0 or -5.0
  }) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final height = mediaQuery.size.height;
    final orientation = mediaQuery.orientation;
    final textScale = mediaQuery.textScaleFactor;
    final devicePixelRatio = mediaQuery.devicePixelRatio;

    // Log when ScaleConfig is created and with what adjustment
    print(
      "ScaleConfig created with globalPixelTextAdjustment: $globalPixelTextAdjustment",
    );

    return ScaleConfig._(
      referenceWidth: refWidth,
      referenceHeight: refHeight,
      referenceDPI: refDPI,
      screenWidth: width,
      screenHeight: height,
      scaleWidth: width / refWidth,
      scaleHeight: height / refHeight,
      textScaleFactor: textScale,
      orientation: orientation,
      devicePixelRatio: devicePixelRatio,
      globalPixelTextAdjustment: globalPixelTextAdjustment,
    );
  }

  double get scaleFactor {
    final baseScale = scaleWidth < scaleHeight ? scaleWidth : scaleHeight;
    final dpiRatio = devicePixelRatio / (referenceDPI / 160);
    final dpiScale = 1.0 + (dpiRatio - 1.0) * 0.05;
    final landscapeMultiplier = orientation == Orientation.landscape
        ? 1.05
        : 1.0;
    return baseScale * dpiScale * landscapeMultiplier;
  }

  double scale(double size) {
    return (size * scaleFactor).clamp(size * 0.8, size * 2.0);
  }

  double scaleText(double fontSize, {double? overridePixelAdjustment}) {
    final double pixelAdjustment =
        overridePixelAdjustment ?? globalPixelTextAdjustment;

    print("\n--- scaleText called ---");
    print("Input fontSize: $fontSize");
    print(
      "Effective pixelAdjustment: $pixelAdjustment (global: $globalPixelTextAdjustment, override: $overridePixelAdjustment)",
    );

    double adjustedTextScaleFactor = textScaleFactor.clamp(0.7, 1.5);
    print(
      "adjustedTextScaleFactor: $adjustedTextScaleFactor (system: $textScaleFactor)",
    );

    double calculatedSize = fontSize * scaleFactor * adjustedTextScaleFactor;
    print("Calculated size (before DPI/clamps): $calculatedSize");

    if (devicePixelRatio > 3.0) {
      calculatedSize *= 0.85;
      print(
        "Applied 0.85 DPI adjustment (devicePixelRatio > 3.0). New calculatedSize: $calculatedSize",
      );
    } else if (devicePixelRatio > 2.5) {
      calculatedSize *= 0.9;
      print(
        "Applied 0.9 DPI adjustment (devicePixelRatio > 2.5). New calculatedSize: $calculatedSize",
      );
    }

    double lowerClampBound = fontSize * 0.7;
    double upperClampBound = fontSize * 1.3;
    double clampedCalculatedSize = calculatedSize.clamp(
      lowerClampBound,
      upperClampBound,
    );
    print(
      "Clamped calculated size (between $lowerClampBound and $upperClampBound): $clampedCalculatedSize",
    );

    double finalSizeAfterAdjustment = clampedCalculatedSize + pixelAdjustment;
    print(
      "Size after pixel adjustment ($pixelAdjustment): $finalSizeAfterAdjustment",
    );

    double finalResult;
    if (pixelAdjustment < 0) {
      finalResult = finalSizeAfterAdjustment.clamp(
        _minAbsFontSize,
        clampedCalculatedSize,
      );
      print(
        "Final result (clamped between $_minAbsFontSize and $clampedCalculatedSize because adjustment is negative): $finalResult",
      );
    } else if (pixelAdjustment > 0) {
      // If increasing, ensure it respects min font size and some reasonable upper bound.
      // The upper bound from original clamp + adjustment might be too large,
      // let's use clampedCalculatedSize + adjustment, but still clamped by a factor of original font size.
      // For simplicity, let's use a slightly more generous upper proportional clamp if increasing.
      double increasedUpperClamp = (fontSize * 1.5) + pixelAdjustment.abs();
      finalResult = finalSizeAfterAdjustment.clamp(
        _minAbsFontSize,
        increasedUpperClamp,
      );
      print(
        "Final result (clamped between $_minAbsFontSize and $increasedUpperClamp because adjustment is positive): $finalResult",
      );
    } else {
      // No adjustment
      finalResult = max(clampedCalculatedSize, _minAbsFontSize);
      print(
        "Final result (no adjustment, max of $clampedCalculatedSize and $_minAbsFontSize): $finalResult",
      );
    }
    print("--- scaleText finished ---\n");
    return finalResult;
  }

  bool get isTablet {
    final shortestSide = screenWidth < screenHeight
        ? screenWidth
        : screenHeight;
    final longestSide = screenWidth > screenHeight ? screenWidth : screenHeight;
    return shortestSide > 600 && longestSide > 900;
  }

  double tabletScale(double size) {
    final baseScaledSize = scale(size);
    if (isTablet) {
      return baseScaledSize * 1.1;
    }
    return baseScaledSize;
  }

  double tabletScaleText(double fontSize, {double? overridePixelAdjustment}) {
    // The globalPixelTextAdjustment (or override) will be applied by the scaleText call.
    print(
      "tabletScaleText called for fontSize: $fontSize, overridePixelAdjustment: $overridePixelAdjustment",
    );
    final baseScaledSize = scaleText(
      fontSize,
      overridePixelAdjustment: overridePixelAdjustment,
    );
    if (isTablet) {
      double tabletScaledSize = baseScaledSize * 1.1;
      double finalTabletSize = max(tabletScaledSize, _minAbsFontSize);
      print(
        "Tablet scaling: baseScaledSize: $baseScaledSize, multiplied: $tabletScaledSize, final (min $_minAbsFontSize): $finalTabletSize",
      );
      return finalTabletSize;
    }
    print("Not a tablet, returning baseScaledSize: $baseScaledSize");
    return baseScaledSize;
  }
}
