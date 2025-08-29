class TotpItem {
  final String id;
  final String serviceName;
  final String username;
  final String secret;
  final String? category;

  TotpItem({
    required this.id,
    required this.serviceName,
    required this.username,
    required this.secret,
    this.category,
  });

  factory TotpItem.fromJson(Map<String, dynamic> json) {
    return TotpItem(
      id: json['id'],
      serviceName: json['serviceName'],
      username: json['username'],
      secret: json['secret'],
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceName': serviceName,
      'username': username,
      'secret': secret,
      'category': category,
    };
  }
}
