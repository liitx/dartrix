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
  accent(0xff63d3c1),
  emphasis(0xffffffff);

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
  badgeCovered('COVERED'),
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
  appTitle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2),
  sectionHeader(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.5),
  badge(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 0.8),
  body(fontSize: 20, fontWeight: FontWeight.w500),
  bodyMuted(fontSize: 22, fontWeight: FontWeight.normal),
  hint(fontSize: 20, fontWeight: FontWeight.normal),
  monoTiny(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    fontFamily: 'monospace',
  ),
  count(fontSize: 14, fontWeight: FontWeight.bold);

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

/// Painter tuning constants. Edit these values to change stroke widths,
/// fill alphas, glow blur radii, vertex sizing, and the disc base
/// gradient. The painter reads every visual knob from here — nothing is
/// hard-coded in `shoelace_painter.dart`.
class AppPaint {
  AppPaint._();

  // ── Region fills ───────────────────────────────────────────────────────

  /// Alpha range for region fills. Floor keeps variant identity readable
  /// (red looks red, orange looks orange); ceiling stays under fully
  /// opaque so the disc gradient still bleeds through covered regions.
  static const double regionAlphaMin = 0.20;
  static const double regionAlphaMax = 0.30;

  // ── Chord stroke ───────────────────────────────────────────────────────

  /// Uniform thickness for every chord. Alpha encodes coverage.
  static const double chordCoreWidth = 2;
  static const double chordAlphaMin = 0.30;
  static const double chordAlphaMax = 1.00;

  /// Wide blurred glow halo painted under fully covered chords.
  static const double chordGlowWidth = 7;
  static const double chordGlowBlur = 5;
  static const double chordGlowAlpha = 0.35;

  // ── Vertex dot ─────────────────────────────────────────────────────────

  /// Solid colored circle at the disc rim.
  static const double vertexCoreRadius = 8;
  static const double vertexFocusedCoreRadius = 5;

  /// Soft halo behind the vertex dot.
  static const double vertexHaloRadius = 9;
  static const double vertexFocusedHaloRadius = 12;
  static const double vertexHaloBlur = 10;
  static const double vertexFocusedHaloBlur = 14;
  static const double vertexHaloAlpha = 0.35;
  static const double vertexFocusedHaloAlpha = 0.55;

  /// Ring drawn around the focused vertex for clarity. Color is
  /// `AppColor.emphasis`.
  static const double vertexFocusRingRadius = 6.5;
  static const double vertexFocusRingStroke = 1.5;

  /// Stroke width of the faint inscribed-circle guide ring under the
  /// chords.
  static const double guideRingStroke = 3;

  // ── Disc base ──────────────────────────────────────────────────────────

  /// Radial gradient tint for the empty disc. Decreasing white overlay
  /// from center to rim builds the "inner depth" feel.
  static const Color discCenterTint = Color(0x22FFFFFF);
  static const Color discMidTint = Color(0x0AFFFFFF);
  static const Color discRimTint = Color(0x00FFFFFF);
  static const List<double> discGradientStops = [0.0, 0.55, 1.0];
}

/// Layout dimensions for the shoelace shell. Centralized so the painter,
/// canvas, and page agree on disc geometry and breakpoints without
/// duplicating constants across files.
class AppLayout {
  AppLayout._();

  /// Viewport width below which the side panel collapses into a Drawer.
  static const double compactBreakpoint = 768;

  /// Side panel width on wide viewports.
  static const double sidePanelWidth = 300;

  /// Maximum body width on very wide viewports. Centered with margin so
  /// the canvas and side panel sit close together rather than spreading
  /// across the full viewport.
  static const double maxBodyWidth = 1100;

  /// Maximum canvas-area height on wide viewports. Caps the canvas + panel
  /// row so the progress bar below it does not drift to the viewport edge.
  static const double canvasAreaHeight = 680;

  /// Maximum diameter the inner shoelace circle ever renders at.
  static const double maxDiscDiameter = 520;

  /// Padding reserved around the disc for label overflow.
  static const double labelPadding = 80;

  /// Maximum width per vertex label before ellipsis kicks in.
  static const double maxLabelWidth = 96;

  /// Disc radius as a fraction of the canvas SizedBox side. Labels render
  /// outside this radius, into the parent Padding via Stack(clipBehavior:
  /// Clip.none).
  static const double discRadiusRatio = 0.88;

  /// Pixel offset between disc rim and the label's anchor point.
  static const double labelGap = 12;
}
