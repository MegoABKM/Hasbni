import 'package:flutter/material.dart';
import 'package:hasbni/core/utils/scale_config.dart';

extension ThemeContext on BuildContext {
  ThemeData get appTheme => Theme.of(this);
  TextTheme get appTextTheme => Theme.of(this).textTheme;
  ScaleConfig get scaleConfig => ScaleConfig(this);
}
