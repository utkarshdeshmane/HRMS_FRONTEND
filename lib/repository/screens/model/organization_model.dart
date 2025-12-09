// lib/models/organization_model.dart

class Organization {
  final String id;
  final String orgName;

  Organization({
    required this.id,
    required this.orgName,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['_id'] ?? json['id'], // MongoDB uses _id
      orgName: json['orgName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orgName': orgName,
    };
  }
}