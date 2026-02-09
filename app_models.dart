class User {
  final int? id;
  final String username;
  final String? email;
  final String role;
  final int? categoryId;

  User({
    this.id,
    required this.username,
    this.email,
    required this.role,
    this.categoryId,
  });

  factory User.fromJson(dynamic json) {
    if (json == null || json is! Map) {
      return User(username: 'Unknown', role: 'user');
    }
    final root = Map<String, dynamic>.from(json);
    
    // Look deeper for user data if wrapped
    Map<String, dynamic> data = root;
    if (root.containsKey('user') && root['user'] is Map) {
      data = Map<String, dynamic>.from(root['user']);
    } else if (root.containsKey('data') && root['data'] is Map) {
      data = Map<String, dynamic>.from(root['data']);
    } else if (root.containsKey('details') && root['details'] is Map) {
      data = Map<String, dynamic>.from(root['details']);
    }

    return User(
      id: int.tryParse((data['id'] ?? data['userId'] ?? data['user_id'] ?? data['user_no'] ?? '').toString()),
      username: (data['username'] ?? data['name'] ?? data['user_name'] ?? 'User').toString(),
      email: (data['email'] ?? '').toString(),
      role: (data['role'] ?? data['user_role'] ?? root['role'] ?? 'user').toString().trim().toLowerCase(),
      categoryId: int.tryParse((data['category_id'] ?? data['cat_id'] ?? '').toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
      'category_id': categoryId,
    };
  }
}

class Category {
  final int id;
  final String name;
  final String? createdAt;

  Category({
    required this.id,
    required this.name,
    this.createdAt,
  });

  factory Category.fromJson(dynamic json) {
    if (json == null || json is! Map) {
      return Category(id: 0, name: 'Unknown');
    }
    final root = Map<String, dynamic>.from(json);
    
    Map<String, dynamic> data = root;
    if (root.containsKey('category') && root['category'] is Map) {
      data = Map<String, dynamic>.from(root['category']);
    } else if (root.containsKey('data') && root['data'] is Map) {
      data = Map<String, dynamic>.from(root['data']);
    }

    return Category(
      id: int.tryParse((data['id'] ?? data['cat_id'] ?? data['category_id'] ?? '').toString()) ?? 0,
      name: (data['name'] ?? data['category_name'] ?? 'Category').toString(),
      createdAt: (data['created_at'] ?? data['timestamp'] ?? '').toString(),
    );
  }
}

class ComplaintResponse {
  final int? id;
  final String adminUsername;
  final String text;
  final String createdAt;

  ComplaintResponse({
    this.id,
    required this.adminUsername,
    required this.text,
    required this.createdAt,
  });

  factory ComplaintResponse.fromJson(dynamic json) {
    if (json == null || json is! Map) {
      return ComplaintResponse(adminUsername: 'Admin', text: '', createdAt: '');
    }
    final data = Map<String, dynamic>.from(json);
    return ComplaintResponse(
      id: int.tryParse((data['id'] ?? data['response_id'] ?? data['res_id'] ?? '').toString()),
      adminUsername: (data['admin_username'] ?? data['admin_name'] ?? data['responder'] ?? 'Admin').toString(),
      text: (data['text'] ?? data['response_text'] ?? data['message'] ?? data['content'] ?? '').toString(),
      createdAt: (data['created_at'] ?? data['timestamp'] ?? '').toString(),
    );
  }
}

class Complaint {
  final int id;
  final String title;
  final String description;
  final String status;
  final String categoryName;
  final int? categoryId;
  final String? userUsername;
  final int? userId;
  final String createdAt;
  final List<ComplaintResponse> responses;
  final List<String> mediaUrls;
  final List<String> mediaTypes;

  Complaint({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.categoryName,
    this.categoryId,
    this.userUsername,
    this.userId,
    required this.createdAt,
    required this.responses,
    this.mediaUrls = const [],
    this.mediaTypes = const [],
  });

  bool get hasMedia => mediaUrls.isNotEmpty;
  int get mediaCount => mediaUrls.length;
  int get imageCount => mediaTypes.where((t) => t == 'image').length;
  int get videoCount => mediaTypes.where((t) => t == 'video').length;

  factory Complaint.fromJson(dynamic json) {
    if (json == null || json is! Map) {
      return Complaint(id: 0, title: 'Error', description: '', status: 'unknown', categoryName: 'Unknown', createdAt: '', responses: []);
    }
    final root = Map<String, dynamic>.from(json);
    
    Map<String, dynamic> data = root;
    if (root.containsKey('complaint') && root['complaint'] is Map) {
      data = Map<String, dynamic>.from(root['complaint']);
    } else if (root.containsKey('data') && root['data'] is Map) {
      data = Map<String, dynamic>.from(root['data']);
    }

    final rawResponses = data['responses'] ?? data['complaint_responses'] ?? data['response'] ?? data['complaint_response'];
    final List<dynamic> responseList = rawResponses is List ? rawResponses : [];
    
    List<ComplaintResponse> responses = responseList
        .map((r) => ComplaintResponse.fromJson(r))
        .toList();

    // Parse media URLs and types
    List<String> mediaUrls = [];
    List<String> mediaTypes = [];
    
    final rawMediaUrls = data['media_urls'] ?? data['mediaUrls'] ?? data['media'];
    final rawMediaTypes = data['media_types'] ?? data['mediaTypes'];
    
    if (rawMediaUrls is String && rawMediaUrls.isNotEmpty) {
      mediaUrls = rawMediaUrls.split(',').where((s) => s.trim().isNotEmpty).toList();
    } else if (rawMediaUrls is List) {
      mediaUrls = rawMediaUrls.map((e) => e.toString()).toList();
    }
    
    if (rawMediaTypes is String && rawMediaTypes.isNotEmpty) {
      mediaTypes = rawMediaTypes.split(',').where((s) => s.trim().isNotEmpty).toList();
    } else if (rawMediaTypes is List) {
      mediaTypes = rawMediaTypes.map((e) => e.toString()).toList();
    }

    return Complaint(
      id: int.tryParse((data['id'] ?? data['complaint_id'] ?? data['comp_id'] ?? '').toString()) ?? 0,
      title: (data['title'] ?? data['subject'] ?? 'No Title').toString(),
      description: (data['description'] ?? data['message'] ?? data['content'] ?? '').toString(),
      status: (data['status'] ?? data['comp_status'] ?? 'pending').toString().toLowerCase(),
      categoryName: (data['category_name'] ?? data['category'] ?? data['cat_name'] ?? 'General').toString(),
      categoryId: int.tryParse((data['category_id'] ?? data['cat_id'] ?? '').toString()),
      userUsername: (data['user_username'] ?? data['username'] ?? data['user_name'] ?? '').toString(),
      userId: int.tryParse((data['user_id'] ?? data['user_no'] ?? '').toString()),
      createdAt: (data['created_at'] ?? data['timestamp'] ?? '').toString(),
      responses: responses,
      mediaUrls: mediaUrls,
      mediaTypes: mediaTypes,
    );
  }
}

class SystemSettings {
  final String supportNumber;
  final String faqUrl;
  final String helpText;

  SystemSettings({
    required this.supportNumber,
    required this.faqUrl,
    required this.helpText,
  });

  factory SystemSettings.fromJson(dynamic json) {
    if (json == null || json is! Map) {
      return SystemSettings(supportNumber: '...', faqUrl: '#', helpText: '');
    }
    final root = Map<String, dynamic>.from(json);
    Map<String, dynamic> data = root;
    if (root.containsKey('settings') && root['settings'] is Map) {
      data = Map<String, dynamic>.from(root['settings']);
    } else if (root.containsKey('data') && root['data'] is Map) {
      data = Map<String, dynamic>.from(root['data']);
    }

    return SystemSettings(
      supportNumber: (data['support_number'] ?? data['phone'] ?? data['contact'] ?? '+1 234 567 890').toString(),
      faqUrl: (data['faq_url'] ?? data['faq'] ?? data['help_url'] ?? 'https://example.com/faq').toString(),
      helpText: (data['help_text'] ?? data['help'] ?? data['message'] ?? 'How can we help you?').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'support_number': supportNumber,
    'faq_url': faqUrl,
    'help_text': helpText,
  };
}