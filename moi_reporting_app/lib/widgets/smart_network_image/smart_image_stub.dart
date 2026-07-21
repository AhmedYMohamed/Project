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
  return Image.network(
    url,
    width: width,
    height: height,
    fit: fit,
    headers: headers ?? const {'Accept': 'image/*'},
    loadingBuilder: (context, child, progress) {
      if (progress == null) return child;
      if (loadingBuilder != null) return loadingBuilder(context);
      return const Center(child: CircularProgressIndicator());
    },
    errorBuilder: errorBuilder,
  );
}
