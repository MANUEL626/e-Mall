// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get languageTitle => '语言';

  @override
  String get languageFrench => '法语';

  @override
  String get languageEnglish => '英语';

  @override
  String get languageGerman => '德语';

  @override
  String get languageChinese => '中文';

  @override
  String get languageSystemDefault => '默认：使用手机语言；不支持时使用法语';

  @override
  String get onboardingHandpicked => '精选';

  @override
  String get onboardingBrandTitle => 'e-Mall';

  @override
  String get onboardingWelcomeSubtitle => '探索一个精选市场，让传统工艺与高端数字购物相遇。';

  @override
  String get continueButton => '继续';

  @override
  String get onboardingPhoneTitle => '欢迎回来';

  @override
  String get onboardingPhoneSubtitle => '输入手机号以访问你的精选商品。';

  @override
  String get labelCountry => '国家';

  @override
  String get labelPhoneNumber => '手机号';

  @override
  String get phoneNationalHint => '号码';

  @override
  String get phoneNationalHintNg => '80 000 0000';

  @override
  String get chooseCountryTitle => '选择国家';

  @override
  String get verificationCodeTitle => '验证码';

  @override
  String otpSentToPhone(String phone) {
    return '验证码已发送至 $phone。';
  }

  @override
  String get otpSentGeneric => '我们已向你的手机发送 6 位验证码。';

  @override
  String get resendCode => '重新发送验证码';

  @override
  String resendCodeSeconds(int seconds) {
    return '$seconds 秒后重新发送';
  }

  @override
  String get verifyCodeButton => '验证';

  @override
  String get skipButton => '跳过';

  @override
  String get profileWelcomeNew => '欢迎！';

  @override
  String get profileWelcomeComplete => '完善你的资料';

  @override
  String get profileAllFieldsOptional => '所有字段均为可选。';

  @override
  String get profilePrefsTitle => '偏好设置';

  @override
  String get profilePrefsSubtitle => '用于个性化商品、语言和配送默认设置。';

  @override
  String get labelDefaultLongitude => '默认经度';

  @override
  String get labelDefaultLatitude => '默认纬度';

  @override
  String get labelInterests => '兴趣';

  @override
  String get interestElectronics => '电子产品';

  @override
  String get interestAppliances => '家用电器';

  @override
  String get interestClothing => '服装';

  @override
  String get interestFood => '食品';

  @override
  String get interestBeauty => '美妆';

  @override
  String get interestSports => '运动';

  @override
  String get interestHome => '家居';

  @override
  String get interestOther => '其他';

  @override
  String get removePhotoTooltip => '移除照片';

  @override
  String get chooseFromGallery => '从相册选择图片';

  @override
  String get labelUsername => '用户名';

  @override
  String get labelFirstName => '名';

  @override
  String get labelLastName => '姓';

  @override
  String get labelEmail => '电子邮箱';

  @override
  String get hintUsername => '例如 neo_artisan';

  @override
  String get hintFirstName => '名';

  @override
  String get hintLastName => '姓';

  @override
  String get hintEmail => 'you@example.com';

  @override
  String get saveButton => '保存';

  @override
  String get errorSupabaseNotConfigured =>
      'Supabase 未配置。请使用 --dart-define=SUPABASE_URL=... 和 SUPABASE_ANON_KEY=... 启动应用';

  @override
  String errorPhoneInvalid(int minNsn, int maxNsn, String countryName) {
    return '请输入有效的国家代码和本地号码（$countryName 需要 $minNsn-$maxNsn 位数字）。';
  }

  @override
  String get errorApiBaseUrlOtp =>
      'API_BASE_URL 未配置。请添加 --dart-define=API_BASE_URL=https://your-api';

  @override
  String get errorApiBaseUrlProfile => 'API_BASE_URL 未配置。';

  @override
  String get errorOtpLength => '请输入短信中的 6 位数字。';

  @override
  String get errorGalleryUnavailable =>
      '相册不可用：请执行完整构建（查看控制台信息，或停止应用，运行 flutter clean、flutter pub get，卸载应用后再 flutter run）。';

  @override
  String get errorSessionExpired => '会话已过期。请重新登录。';

  @override
  String get errorInvalidEmail => '电子邮箱地址无效。';

  @override
  String get errorInvalidCoordinates => '请输入有效的经度和纬度。';

  @override
  String get snackAddedToCart => '已加入购物车';

  @override
  String get retryButton => '重试';

  @override
  String get feedEmptyPosts => '暂无动态。';

  @override
  String get feedFollowingBadge => '已关注';

  @override
  String get feedViewMerchant => '查看店铺';

  @override
  String get snackSubscriptionCancelled => '已取消关注';

  @override
  String get snackFollowingShop => '你正在关注此店铺';

  @override
  String get subscribeButton => '关注';

  @override
  String get unsubscribeButton => '取消关注';

  @override
  String get snackMinMaxPrice => '最低价必须小于或等于最高价。';

  @override
  String get applyButton => '应用';

  @override
  String get resetButton => '重置';

  @override
  String get navHome => '首页';

  @override
  String get navNew => '动态';

  @override
  String get navMe => '我的';

  @override
  String get homeSearchTooltip => '搜索';

  @override
  String get homeFiltersTooltip => '筛选';

  @override
  String get homeSearchHint => '搜索商品…';

  @override
  String get homeHeroTitle => '夏日\n丰收\n精选';

  @override
  String get homeHeroSubtitle => '从肥沃山谷农场直接送到你的厨房。';

  @override
  String get homeCategoriesTitle => '分类';

  @override
  String get homeSelectionTitle => '精选';

  @override
  String get homeAllCategories => '全部';

  @override
  String get homeEmptyCatalog => '没有符合搜索或筛选条件的商品。';

  @override
  String get filterSheetTitle => '筛选';

  @override
  String get filterCategoryLabel => '分类';

  @override
  String get filterPriceLabel => '单价（最低 / 最高）';

  @override
  String filterPriceSummary(String min, String max) {
    return '价格 $min - $max';
  }

  @override
  String get errorApiNotConfigured => 'API_BASE_URL 未配置（dart-define）。';

  @override
  String get errorSessionMissing => '会话不存在。请重新登录。';

  @override
  String get merchantDefaultShopName => '店铺';

  @override
  String subscriberCount(int count) {
    return '$count 位关注者';
  }

  @override
  String get ordersTitle => '我的订单';

  @override
  String get ordersFilterAll => '全部';

  @override
  String get ordersFilterInProgress => '处理中';

  @override
  String get ordersFilterInDelivery => '配送中';

  @override
  String get ordersFilterCancelled => '已取消';

  @override
  String get ordersFilterCompleted => '已完成';

  @override
  String get ordersEmpty => '此分类暂无订单。';

  @override
  String ordersArticlesCount(int count) {
    return '$count 件商品';
  }

  @override
  String get orderDetailTitle => '订单';

  @override
  String get orderShopLabel => '店铺';

  @override
  String get orderPlacedLabel => '下单时间';

  @override
  String get orderArticlesTitle => '商品';

  @override
  String get orderFulfillmentPickup => '自取';

  @override
  String get orderFulfillmentDelivery => '配送';

  @override
  String get orderStatusPending => '待处理';

  @override
  String get orderStatusInProgress => '处理中';

  @override
  String get orderStatusInDelivery => '配送中';

  @override
  String get orderStatusCancelled => '已取消';

  @override
  String get orderStatusCompleted => '已完成';

  @override
  String get meOrderHistoryTitle => '订单历史';

  @override
  String get meOrderHistorySubtitle => '跟踪并查看你的购买记录';

  @override
  String get meProfileFallback => '资料';

  @override
  String get meCompleteProfile => '完善你的资料';

  @override
  String get meOrdersStat => '订单';

  @override
  String get meWishlistStat => '收藏';

  @override
  String get mePointsStat => '积分';

  @override
  String get meAccountTitle => '我的账户';

  @override
  String get meAccountSubtitle => '钱包、支付和账单';

  @override
  String get meWishlistTitle => '我的收藏';

  @override
  String get meWishlistSubtitle => '你喜欢的商品';

  @override
  String get meCartTitle => '我的购物车';

  @override
  String get meCartSubtitle => '准备结算的商品';

  @override
  String get orderConfirmReceiptTitle => '确认收货';

  @override
  String get orderConfirmReceiptScanTooltip => '扫描收货二维码';

  @override
  String get orderConfirmReceiptHint => '将摄像头对准店铺或配送员出示的二维码。二维码包含订单编号和验证密钥。';

  @override
  String get orderConfirmReceiptNoteLabel => '备注（可选）';

  @override
  String get orderConfirmReceiptSuccess => '已确认收货。';

  @override
  String get orderDetailConfirmReceipt => '确认收货（二维码）';

  @override
  String get orderManualQrLabel => '粘贴二维码内容';

  @override
  String get orderManualQrSubmit => '提交';

  @override
  String get orderScannerWebHint => '浏览器中的摄像头扫描可能受限；如有需要，请在下方粘贴二维码内容。';

  @override
  String get settingsTitle => '设置';

  @override
  String get editProfileTooltip => '编辑资料';

  @override
  String get settingsProfileSection => '资料';

  @override
  String get settingsPreferencesSection => '偏好设置';

  @override
  String get settingsAccountSection => '账户';

  @override
  String get settingsInterestsSection => '兴趣';

  @override
  String get settingsNameLabel => '姓名';

  @override
  String get settingsPhoneLabel => '电话';

  @override
  String get settingsLocationLabel => '位置';

  @override
  String get settingsRegionLabel => '地区';

  @override
  String get settingsLanguageLabel => '语言';

  @override
  String get settingsUndefined => '未设置';

  @override
  String get profileUpdateTitle => '编辑资料';

  @override
  String get profileUpdateSaveTooltip => '保存';

  @override
  String get profileUpdateGenericError => '无法更新资料。请重试。';

  @override
  String get profileUpdateConflictError => '邮箱或用户名已被使用。请选择其他值。';

  @override
  String get profileUpdatePhotoError => '无法选择这张照片。';

  @override
  String get profileUpdateLocationTitle => '位置';

  @override
  String get profileUpdateLocationSubtitle => '使用当前位置或点击地图。';

  @override
  String get profileUpdateExpiredSession => '会话已过期。请重新登录。';

  @override
  String get signOutMenuTitle => '退出登录';

  @override
  String get signOutMenuSubtitle => '从 e-Mall 断开此手机';

  @override
  String get signOutDialogTitle => '要退出登录吗？';

  @override
  String get signOutDialogBody => '你需要再次使用手机号登录。';

  @override
  String get signOutConfirm => '退出登录';

  @override
  String get signOutCancel => '取消';
}
