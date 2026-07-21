import 'package:flutter/material.dart';

/// Central palette for the Officer app.
/// Ordered darkest -> lightest so gradients read naturally top-to-bottom
/// or dark-to-light across widgets.
class AppColors {
  AppColors._();

  static const Color deepTwilight = Color(0xFF03045E);
  static const Color frenchBlue = Color(0xFF023E8A);
  static const Color brightTealBlue = Color(0xFF0077B6);
  static const Color blueGreen = Color(0xFF0096C7);
  static const Color turquoiseSurf = Color(0xFF00B4D8);
  static const Color skyAqua = Color(0xFF48CAE4);
  static const Color frostedBlue = Color(0xFF90E0EF);
  static const Color frostedBlue2 = Color(0xFFADE8F4);
  static const Color lightCyan = Color(0xFFCAF0F8);

  // Semantic roles built from the palette, so screens don't hardcode hex values.
  static const Color background = lightCyan;
  static const Color surface = Colors.white;
  static const Color primary = brightTealBlue;
  static const Color primaryDark = deepTwilight;
  static const Color accent = turquoiseSurf;
  static const Color onDark = Colors.white;
  static const Color textPrimary = deepTwilight;
  static const Color textSecondary = Color(0xFF4A6FA5);

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [deepTwilight, frenchBlue, brightTealBlue],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brightTealBlue, turquoiseSurf],
  );

  static const LinearGradient cardGlassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [frostedBlue, frostedBlue2],
  );

  // Status colors stay within/near the palette for Submitted/InProgress/
  // Resolved (which are brand-adjacent states), but keep a conventional
  // muted red for Rejected since red is the one color users universally
  // read as "stop/problem" and no blue reads that way regardless of shade.
  static const Color statusSubmitted = frenchBlue;
  static const Color statusInProgress = turquoiseSurf;
  static const Color statusResolved = Color(0xFF2A9D8F); // teal-green, harmonizes with blueGreen/turquoiseSurf
  static const Color statusRejected = Color(0xFFE76F51); // muted coral-red, only true departure from the palette
  static const Color statusDefault = textSecondary;

  static Color statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'submitted':
        return statusSubmitted;
      case 'inprogress':
        return statusInProgress;
      case 'resolved':
        return statusResolved;
      case 'rejected':
        return statusRejected;
      default:
        return statusDefault;
    }
  }
}
