import 'package:flutter/material.dart';
import '../../services/report_service.dart';

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

  String _resolveUrl(String targetUrl) {
    final trimmed = targetUrl.trim();
    if (trimmed.isEmpty) return trimmed;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://') || trimmed.startsWith('blob:')) {
      return trimmed;
    }
    final base = ReportService.baseUrl.endsWith('/')
        ? ReportService.baseUrl.substring(0, ReportService.baseUrl.length - 1)
        : ReportService.baseUrl;
    final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$base$path';
  }

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = _resolveUrl(url);

    return Image.network(
      resolvedUrl,
      width: width,
      height: height,
      fit: fit,
      headers: headers ?? const {'Accept': 'image/*'},
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        if (loadingBuilder != null) return loadingBuilder!(context);
        return const Center(child: CircularProgressIndicator());
      },
      errorBuilder: errorBuilder,
    );
  }
}
