// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
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
  return _WebImageWidget(
    url: url,
    width: width,
    height: height,
    fit: fit,
    errorBuilder: errorBuilder,
  );
}

class _WebImageWidget extends StatefulWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext, Object, StackTrace?) errorBuilder;

  const _WebImageWidget({
    required this.url,
    this.width,
    this.height,
    required this.fit,
    required this.errorBuilder,
  });

  @override
  State<_WebImageWidget> createState() => _WebImageWidgetState();
}

class _WebImageWidgetState extends State<_WebImageWidget> {
  late String _viewType;
  bool _hasError = false;
  Object? _errorObj;

  @override
  void initState() {
    super.initState();
    _registerImageElement();
  }

  @override
  void didUpdateWidget(covariant _WebImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.fit != widget.fit) {
      _hasError = false;
      _registerImageElement();
    }
  }

  void _registerImageElement() {
    // Unique view ID based on URL hash
    final String viewId = 'img-${widget.url.hashCode}-${DateTime.now().microsecondsSinceEpoch}';
    _viewType = viewId;

    ui_web.platformViewRegistry.registerViewFactory(
      viewId,
      (int id) {
        final img = html.ImageElement()
          ..src = widget.url
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = _cssObjectFit(widget.fit)
          ..style.border = 'none'
          ..style.margin = '0'
          ..style.padding = '0';

        img.onError.listen((event) {
          if (mounted) {
            setState(() {
              _hasError = true;
              _errorObj = 'Failed to load image via HTML <img> element on web.';
            });
          }
        });

        return img;
      },
    );
  }

  String _cssObjectFit(BoxFit fit) {
    switch (fit) {
      case BoxFit.cover:
        return 'cover';
      case BoxFit.contain:
        return 'contain';
      case BoxFit.fill:
        return 'fill';
      case BoxFit.fitWidth:
        return 'fit-width';
      case BoxFit.fitHeight:
        return 'fit-height';
      case BoxFit.scaleDown:
        return 'scale-down';
      default:
        return 'contain';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Image.network(
        widget.url,
        width: widget.width ?? double.infinity,
        height: widget.height ?? double.infinity,
        fit: widget.fit,
        errorBuilder: widget.errorBuilder,
      );
    }

    return SizedBox(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      child: HtmlElementView(viewType: _viewType),
    );
  }
}
