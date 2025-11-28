/// Color configuration for a Dash panel.
///
/// Allows customization of the primary, danger, warning, success, and info
/// colors used throughout the admin panel UI.
///
/// Colors should be specified as Tailwind CSS color names (without the shade),
/// e.g., 'cyan', 'blue', 'indigo', 'violet', 'purple', 'pink', 'rose', etc.
///
/// Example:
/// ```dart
/// final panel = Panel()
///   ..colors(PanelColors(
///     primary: 'indigo',
///     danger: 'red',
///   ));
/// ```
class PanelColors {
  /// Primary brand color (default: 'cyan').
  /// Used for primary buttons, focus rings, active states, links.
  final String primary;

  /// Danger/destructive color (default: 'red').
  /// Used for delete buttons, error states, destructive actions.
  final String danger;

  /// Warning color (default: 'amber').
  /// Used for warning messages and caution states.
  final String warning;

  /// Success color (default: 'green').
  /// Used for success messages and positive states.
  final String success;

  /// Info color (default: 'blue').
  /// Used for informational messages and neutral highlights.
  final String info;

  const PanelColors({
    this.primary = 'cyan',
    this.danger = 'red',
    this.warning = 'amber',
    this.success = 'green',
    this.info = 'blue',
  });

  /// Default Dash color scheme using cyan as primary.
  static const PanelColors defaults = PanelColors();

  // ============================================
  // PRIMARY COLOR CLASSES
  // ============================================

  /// Primary background color (e.g., 'bg-cyan-500').
  String get primaryBg => 'bg-$primary-500';

  /// Primary background hover (e.g., 'hover:bg-cyan-600').
  String get primaryBgHover => 'hover:bg-$primary-600';

  /// Primary background active (e.g., 'active:bg-cyan-700').
  String get primaryBgActive => 'active:bg-$primary-700';

  /// Primary text color (e.g., 'text-cyan-500').
  String get primaryText => 'text-$primary-500';

  /// Primary text lighter shade (e.g., 'text-cyan-400').
  String get primaryTextLight => 'text-$primary-400';

  /// Primary text hover (e.g., 'hover:text-cyan-300').
  String get primaryTextHover => 'hover:text-$primary-300';

  /// Primary border color (e.g., 'border-cyan-500').
  String get primaryBorder => 'border-$primary-500';

  /// Primary focus ring (e.g., 'focus:ring-cyan-500').
  String get primaryFocusRing => 'focus:ring-$primary-500';

  /// Primary focus ring with opacity (e.g., 'focus:ring-cyan-500/50').
  String get primaryFocusRingFaded => 'focus:ring-$primary-500/50';

  /// Focus within ring (e.g., 'focus-within:ring-cyan-500').
  String get primaryFocusWithinRing => 'focus-within:ring-$primary-500';

  /// Primary ring offset color.
  String get primaryRingOffset => 'focus:ring-offset-2 focus:ring-offset-gray-900';

  // ============================================
  // DANGER COLOR CLASSES
  // ============================================

  String get dangerBg => 'bg-$danger-600';
  String get dangerBgHover => 'hover:bg-$danger-700';
  String get dangerBgActive => 'active:bg-$danger-800';
  String get dangerText => 'text-$danger-500';
  String get dangerTextLight => 'text-$danger-400';
  String get dangerFocusRing => 'focus:ring-$danger-500';

  // ============================================
  // WARNING COLOR CLASSES
  // ============================================

  String get warningBg => 'bg-$warning-500';
  String get warningBgHover => 'hover:bg-$warning-600';
  String get warningBgActive => 'active:bg-$warning-700';
  String get warningText => 'text-$warning-500';
  String get warningTextLight => 'text-$warning-400';
  String get warningFocusRing => 'focus:ring-$warning-500';

  // ============================================
  // SUCCESS COLOR CLASSES
  // ============================================

  String get successBg => 'bg-$success-600';
  String get successBgHover => 'hover:bg-$success-700';
  String get successBgActive => 'active:bg-$success-800';
  String get successText => 'text-$success-500';
  String get successTextLight => 'text-$success-400';
  String get successFocusRing => 'focus:ring-$success-500';

  // ============================================
  // INFO COLOR CLASSES
  // ============================================

  String get infoBg => 'bg-$info-600';
  String get infoBgHover => 'hover:bg-$info-700';
  String get infoBgActive => 'active:bg-$info-800';
  String get infoText => 'text-$info-500';
  String get infoTextLight => 'text-$info-400';
  String get infoFocusRing => 'focus:ring-$info-500';

  // ============================================
  // COMPOSITE STYLES
  // ============================================

  /// Full primary button classes.
  String get buttonPrimary =>
      '$primaryBg text-white $primaryBgHover $primaryBgActive focus:ring-2 $primaryFocusRing $primaryRingOffset';

  /// Full danger button classes.
  String get buttonDanger =>
      '$dangerBg text-white $dangerBgHover $dangerBgActive focus:ring-2 $dangerFocusRing $primaryRingOffset';

  /// Full warning button classes.
  String get buttonWarning =>
      '$warningBg text-white $warningBgHover $warningBgActive focus:ring-2 $warningFocusRing $primaryRingOffset';

  /// Full success button classes.
  String get buttonSuccess =>
      '$successBg text-white $successBgHover $successBgActive focus:ring-2 $successFocusRing $primaryRingOffset';

  /// Full info button classes.
  String get buttonInfo =>
      '$infoBg text-white $infoBgHover $infoBgActive focus:ring-2 $infoFocusRing $primaryRingOffset';

  /// Subtle primary button (text colored, gray bg).
  String get buttonPrimarySubtle => '$primaryTextLight $primaryTextHover bg-gray-700 hover:bg-gray-600';

  /// Subtle danger button.
  String get buttonDangerSubtle => '$dangerTextLight hover:text-white bg-gray-700 hover:bg-$danger-600';

  /// Input focus ring classes.
  String get inputFocus => 'focus:outline-none focus:ring-2 $primaryFocusRingFaded focus:$primaryBorder';

  /// Focus-within ring for wrapper elements.
  String get wrapperFocusWithin => 'focus-within:ring-2 $primaryFocusWithinRing focus-within:border-transparent';

  /// Checkbox/toggle checked color.
  String get checkboxChecked => 'text-$primary-500';

  /// Accent text for branding.
  String get accentText => primaryTextLight;

  /// Glow effect background (with opacity).
  String glowBg([int opacity = 20]) => 'bg-$primary-500/$opacity';

  @override
  String toString() =>
      'PanelColors(primary: $primary, danger: $danger, warning: $warning, success: $success, info: $info)';
}
