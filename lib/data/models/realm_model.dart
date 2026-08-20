class RealmModel {
  const RealmModel({
    required this.id,
    required this.name,
    required this.handle,
    required this.type,
    required this.status,
    this.parentId,
    this.description,
    this.purpose,
    this.primaryTheme,
    this.primaryFocus,
    this.tags,
    this.avatar,
    this.visibility,
    this.wallet,
    this.memberCount = 0,
    this.members,
    this.createdAt,
  });

  final String id;
  final String name;
  final String handle;
  final String type;
  final String status;
  final String? parentId;
  final String? description;
  final String? purpose;
  final String? primaryTheme;
  final String? primaryFocus;
  final List<String>? tags;
  final String? avatar;
  final String? visibility;
  final String? wallet;
  final int memberCount;
  final List<RealmMember>? members;
  final DateTime? createdAt;

  factory RealmModel.fromJson(Map<String, dynamic> json) {
    final membersList = json['members'] as List<dynamic>?;
    return RealmModel(
      id: json['id'] as String,
      name: json['name'] as String,
      handle: json['handle'] as String,
      type: json['type'] as String,
      status: json['status'] as String? ?? 'draft',
      parentId: json['parent_id'] as String? ?? json['parentId'] as String?,
      description: json['description'] as String?,
      purpose: json['purpose'] as String?,
      primaryTheme:
          json['primary_theme'] as String? ?? json['primaryTheme'] as String?,
      primaryFocus:
          json['primary_focus'] as String? ?? json['primaryFocus'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>(),
      avatar: json['avatar'] as String?,
      visibility: json['visibility'] as String?,
      wallet: json['wallet'] as String?,
      memberCount: membersList?.length ?? 0,
      members: membersList
          ?.map(
            (m) => RealmMember.fromJson(m as Map<String, dynamic>),
          )
          .toList(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'handle': handle,
      'type': type,
      'status': status,
      'parent_id': parentId,
      'description': description,
      'purpose': purpose,
      'primary_theme': primaryTheme,
      'primary_focus': primaryFocus,
      'tags': tags,
      'avatar': avatar,
      'visibility': visibility,
      'wallet': wallet,
      'members': members?.map((m) => m.toJson()).toList(),
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class RealmMember {
  const RealmMember({
    required this.wallet,
    required this.role,
    this.isSigner = false,
  });

  final String wallet;
  final String role;
  final bool isSigner;

  factory RealmMember.fromJson(Map<String, dynamic> json) {
    return RealmMember(
      wallet: json['wallet'] as String,
      role: json['role'] as String? ?? 'member',
      isSigner:
          json['is_signer'] as bool? ?? json['isSigner'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wallet': wallet,
      'role': role,
      'is_signer': isSigner,
    };
  }
}
