/// Modèles alignés sur `GET /api/v1/customers/posts/feed` (`guide_api.md`).
class ArticlePostFeedItem {
  const ArticlePostFeedItem({
    required this.organizationId,
    required this.organizationName,
    required this.organizationArticleId,
    required this.name,
    required this.category,
    required this.unitSalePrice,
    required this.stockStatus,
    this.primaryImageStoragePath,
    this.additionalImageStoragePaths = const [],
    this.description,
    required this.slot,
    required this.mediaKind,
    required this.mediaStoragePath,
    this.videoMobileLowStoragePath,
    this.thumbnailStoragePath,
    this.processingStatus = 'ready',
    this.mediaWidth,
    this.mediaHeight,
    this.mediaDurationSeconds,
    this.caption,
  });

  final String organizationId;
  final String organizationName;
  final String organizationArticleId;
  final String name;
  final String category;
  final String unitSalePrice;
  final String stockStatus;
  final String? primaryImageStoragePath;
  final List<String> additionalImageStoragePaths;
  final String? description;
  final int slot;

  /// `image` ou `video` (API).
  final String mediaKind;
  final String mediaStoragePath;
  final String? videoMobileLowStoragePath;
  final String? thumbnailStoragePath;
  final String processingStatus;
  final int? mediaWidth;
  final int? mediaHeight;
  final double? mediaDurationSeconds;
  final String? caption;

  bool get isVideo => mediaKind.trim().toLowerCase() == 'video';
  bool get isVideoReady =>
      isVideo && processingStatus.trim().toLowerCase() == 'ready';

  String get preferredVideoStoragePath {
    final mobileLow = videoMobileLowStoragePath?.trim();
    if (mobileLow != null && mobileLow.isNotEmpty) return mobileLow;
    return mediaStoragePath.trim();
  }

  factory ArticlePostFeedItem.fromJson(Map<String, dynamic> json) {
    return ArticlePostFeedItem(
      organizationId: json['organization_id'] as String? ?? '',
      organizationName: json['organization_name'] as String? ?? '',
      organizationArticleId: json['organization_article_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'other',
      unitSalePrice: json['unit_sale_price']?.toString() ?? '0',
      stockStatus: json['stock_status'] as String? ?? 'out_of_stock',
      primaryImageStoragePath: json['primary_image_storage_path'] as String?,
      additionalImageStoragePaths:
          (json['additional_image_storage_paths'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
          const [],
      description: json['description'] as String?,
      slot: (json['slot'] as num?)?.toInt() ?? 1,
      mediaKind: json['media_kind'] as String? ?? 'image',
      mediaStoragePath: json['media_storage_path'] as String? ?? '',
      videoMobileLowStoragePath: json['video_mobile_low_storage_path'] as String?,
      thumbnailStoragePath: json['thumbnail_storage_path'] as String?,
      processingStatus: json['processing_status'] as String? ?? 'ready',
      mediaWidth: (json['media_width'] as num?)?.toInt(),
      mediaHeight: (json['media_height'] as num?)?.toInt(),
      mediaDurationSeconds: (json['media_duration_seconds'] as num?)?.toDouble(),
      caption: json['caption'] as String?,
    );
  }
}

class PostFeedPage {
  const PostFeedPage({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  final List<ArticlePostFeedItem> items;
  final int total;
  final int limit;
  final int offset;

  factory PostFeedPage.fromJson(Map<String, dynamic> json) {
    final raw = json['items'] as List<dynamic>? ?? const [];
    return PostFeedPage(
      items: raw
          .map((e) => ArticlePostFeedItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 0,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
    );
  }
}
