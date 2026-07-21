import 'dart:html' as html;

bool isReloadNavigation() {
  try {
    final navType = html.window.performance.navigation.type;
    return navType == 1; // 1 is TYPE_RELOAD
  } catch (e) {
    return false;
  }
}
