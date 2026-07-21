import 'package:flutter/material.dart';

Widget buildSmartImage({
  required String url,
  double? width,
  double? height,
  BoxFit fit = BoxFit.contain,
  required Widget Function(BuildContext, Object, StackTrace?) errorBuilder,
  Widget Function(BuildContext)? loadingBuilder,
  Map<String, String>? headers,
}) {
  throw UnsupportedError('Cannot create SmartImage without platform implementation');
}
