import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ImagePrefetchService {
  final DefaultCacheManager _cacheManager;

  ImagePrefetchService({DefaultCacheManager? cacheManager})
      : _cacheManager = cacheManager ?? DefaultCacheManager();

  Future<void> prefetchImages(List<String> urls) async {
    final validUrls = urls.where((url) => url.isNotEmpty).toList();
    if (validUrls.isEmpty) return;

    // Download in batches of 10 to avoid flooding the network
    for (var i = 0; i < validUrls.length; i += 10) {
      final batch = validUrls.skip(i).take(10);
      await Future.wait(
        batch.map((url) => _cacheManager.downloadFile(url)),
        eagerError: true,
      );
    }
  }
}