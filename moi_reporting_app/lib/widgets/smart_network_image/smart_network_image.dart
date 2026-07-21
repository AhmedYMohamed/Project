import 'package:flutter/material.dart';
import 'smart_image_stub.dart'
    if (dart.library.html) 'smart_image_web.dart';

class SmartNetworkImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext, Object, StackTrace?) errorBuilder;
  final Widget Function(BuildContext)? loadingBuilder;
  final Map<String, String>? headers;

  const SmartNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    required this.errorBuilder,
    this.loadingBuilder,
    this.headers,
  });

  @override
  Widget build(BuildContext context) {
    return buildSmartImage(
      url: url,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: errorBuilder,
      loadingBuilder: loadingBuilder,
      headers: headers,
    );
  }
}
