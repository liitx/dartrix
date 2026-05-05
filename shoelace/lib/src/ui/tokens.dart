// tokens.dart — design tokens. Every chrome string and color lives in an
// enum. Bare strings / hardcoded colors anywhere outside this file is a
// review failure.
//
// Adding a new color or label = add an enum case + use it. The exhaustive
// switch shape (no default) keeps things honest.

import 'package:flutter/material.dart';

/// Palette for app chrome (borders, text, backgrounds, status colors).
/// Variant colors come from JSON — those stay as `Color` on `VariantInfo`.
enum AppColor {
  background(0xff14161e),
  border(0xff2a2e3a),
  guideRing(0xff2d3242),
  textPrimary(0xffd4d6e0),
  textMuted(0xff8c93a8),
  textHint(0xff5e6377),
  statusError(0xfff07e7e),
  statusGap(0xffe8c574),
  statusComplete(0xff7fdc8e),
  accent(0xff63d3c1);

  const AppColor(this._value);
  final int _value;

  /// Material `Color` derived from the ARGB int. Alpha is forced to 0xff.
  Color get color => Color(0xff000000 | _value);
}

/// All static UI strings shown by the app. Variant names come from JSON.
enum UiLabel {
  appTitle('SHOELACE COVERAGE'),
  tagline(
    'each variant is a node · each lace is a relation · full lace = 100%',
  ),
  sectionVariants('VARIANTS'),
  sectionLaceSegments('LACE SEGMENTS'),
  stripCoverage('COVERAGE'),
  badgeComplete('COMPLETE'),
  badgeTested('TESTED'),
  badgeGap('GAP'),
  arrow('→'),
  initializing('Initializing…'),
  loadingPrefix('Loading'),
  errorTitle('Coverage data unavailable'),
  appWindowTitle('dartrix shoelace');

  const UiLabel(this.text);
  final String text;
}

/// Layout / spacing scale in logical pixels.
enum AppSpacing {
  xs(4),
  sm(8),
  md(12),
  lg(16),
  xl(20),
  xxl(40);

  const AppSpacing(this.px);
  final double px;
}

/// Typography. Each role declares its complete TextStyle so consumers can
/// drop a single style ref instead of reconstructing every time.
enum AppText {
  appTitle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    letterSpacing: 2,
  ),
  sectionHeader(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.5,
  ),
  badge(
    fontSize: 10,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.8,
  ),
  body(
    fontSize: 13,
    fontWeight: FontWeight.w500,
  ),
  bodyMuted(
    fontSize: 12,
    fontWeight: FontWeight.normal,
  ),
  hint(
    fontSize: 11,
    fontWeight: FontWeight.normal,
  ),
  monoTiny(
    fontSize: 10,
    fontWeight: FontWeight.normal,
    fontFamily: 'monospace',
  ),
  count(
    fontSize: 14,
    fontWeight: FontWeight.bold,
  );

  const AppText({
    required this.fontSize,
    required this.fontWeight,
    this.letterSpacing,
    this.fontFamily,
  });

  final double fontSize;
  final FontWeight fontWeight;
  final double? letterSpacing;
  final String? fontFamily;

  /// Renders to a `TextStyle` with the given color.
  TextStyle styleWith(Color color) => TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        fontFamily: fontFamily,
      );
}
