import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class ImageCacheService {
  static final ImageCacheService instance = ImageCacheService._internal();
  ImageCacheService._internal();

  Directory? _cacheDir;

  Future<Directory> _getCacheDir() async {
    if (_cacheDir != null) return _cacheDir!;
    final tempDir = await getTemporaryDirectory();
    final dir = Directory('${tempDir.path}/nomadtrip_img_cache');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _cacheDir = dir;
    return _cacheDir!;
  }

  String _hashUrl(String url) {
    return url.hashCode.abs().toRadixString(16);
  }

  Future<File?> getLocalImageFile(String url) async {
    if (kIsWeb || url.trim().isEmpty || !url.startsWith('http')) return null;
    try {
      final dir = await _getCacheDir();
      final hash = _hashUrl(url);
      final file = File('${dir.path}/$hash.img');
      if (await file.exists()) {
        return file;
      }
      // Download in background
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode == 200) {
        final bytes = await consolidateHttpClientResponseBytes(response);
        await file.writeAsBytes(bytes);
        return file;
      }
    } catch (_) {}
    return null;
  }
}

class CachedPlaceImage extends StatefulWidget {
  final String imageUrl;
  final String category;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const CachedPlaceImage({
    super.key,
    required this.imageUrl,
    this.category = 'attraction',
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  State<CachedPlaceImage> createState() => _CachedPlaceImageState();
}

class _CachedPlaceImageState extends State<CachedPlaceImage> {
  File? _localFile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  @override
  void didUpdateWidget(CachedPlaceImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadFile();
    }
  }

  void _loadFile() async {
    if (kIsWeb ||
        widget.imageUrl.trim().isEmpty ||
        !widget.imageUrl.startsWith('http')) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final file = await ImageCacheService.instance.getLocalImageFile(
      widget.imageUrl,
    );
    if (mounted) {
      setState(() {
        _localFile = file;
        _loading = false;
      });
    }
  }

  Widget _buildPlaceholder() {
    IconData icon;
    Color color;
    switch (widget.category) {
      case 'theme_park':
        icon = Icons.attractions_rounded;
        color = const Color(0xFF6366F1);
        break;
      case 'shopping':
        icon = Icons.shopping_bag_rounded;
        color = const Color(0xFFEC4899);
        break;
      case 'food':
        icon = Icons.restaurant_rounded;
        color = const Color(0xFFF97316);
        break;
      case 'transit':
        icon = Icons.directions_car_rounded;
        color = const Color(0xFF64748B);
        break;
      default:
        icon = Icons.landscape_rounded;
        color = const Color(0xFF0F766E);
    }
    return Container(
      width: widget.width,
      height: widget.height,
      color: color.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: Icon(
        icon,
        color: color,
        size: (widget.height != null && widget.height! < 70) ? 24 : 36,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (widget.imageUrl.trim().isEmpty) {
      content = _buildPlaceholder();
    } else if (kIsWeb) {
      content = Image.network(
        widget.imageUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _buildPlaceholder();
        },
      );
    } else if (_localFile != null && _localFile!.existsSync()) {
      content = Image.file(
        _localFile!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    } else if (_loading) {
      content = _buildPlaceholder();
    } else {
      content = Image.network(
        widget.imageUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }

    if (widget.borderRadius != null) {
      return ClipRRect(borderRadius: widget.borderRadius!, child: content);
    }
    return content;
  }
}
