/// Réponses `GET /api/v1/customers/organizations/{id}` et abonnements (`guide_api.md`).
class OrganizationPreview {
  const OrganizationPreview({
    required this.id,
    required this.name,
    required this.subscriberCount,
  });

  final String id;
  final String name;
  final int subscriberCount;

  factory OrganizationPreview.fromJson(Map<String, dynamic> json) {
    return OrganizationPreview(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      subscriberCount: (json['subscriber_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class OrganizationSnippet {
  const OrganizationSnippet({
    required this.id,
    required this.name,
    required this.orgType,
  });

  final String id;
  final String name;
  final String orgType;

  factory OrganizationSnippet.fromJson(Map<String, dynamic> json) {
    return OrganizationSnippet(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      orgType: json['org_type'] as String? ?? '',
    );
  }
}

class CustomerSubscriptionItem {
  const CustomerSubscriptionItem({
    required this.id,
    required this.organizationId,
    required this.organization,
    required this.status,
    this.subscribedAt,
    this.cancelledAt,
  });

  final String id;
  final String organizationId;
  final OrganizationSnippet organization;
  final String status;
  final String? subscribedAt;
  final String? cancelledAt;

  factory CustomerSubscriptionItem.fromJson(Map<String, dynamic> json) {
    final orgJson = json['organization'] as Map<String, dynamic>? ?? {};
    return CustomerSubscriptionItem(
      id: json['id'] as String? ?? '',
      organizationId: json['organization_id'] as String? ?? '',
      organization: OrganizationSnippet.fromJson(orgJson),
      status: json['status'] as String? ?? '',
      subscribedAt: json['subscribed_at'] as String?,
      cancelledAt: json['cancelled_at'] as String?,
    );
  }
}

class CustomerSubscriptionsPage {
  const CustomerSubscriptionsPage({required this.items});

  final List<CustomerSubscriptionItem> items;

  factory CustomerSubscriptionsPage.fromJson(Map<String, dynamic> json) {
    final raw = json['items'] as List<dynamic>? ?? const [];
    return CustomerSubscriptionsPage(
      items: raw
          .map((e) => CustomerSubscriptionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
