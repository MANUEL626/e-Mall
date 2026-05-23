import '../../core/feeds/customer_feed_service.dart';

export '../../core/feeds/article_post_feed_models.dart';
export '../../core/feeds/customer_feed_service.dart';

class NewsService {
  NewsService._();

  static CustomerFeedService get instance => CustomerFeedService.instance;
}
