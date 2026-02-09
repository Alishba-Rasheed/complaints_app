import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/app_models.dart';
import '../services/chat_service.dart';
import 'package:dio/dio.dart';

class ComplaintProvider with ChangeNotifier {
  List<Complaint> _complaints = [];
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;
  final ApiService _apiService = ApiService();

  List<Complaint> get complaints => _complaints;
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void startWatchingCategories() {
    ChatService().watchCategories().listen((list) {
      if (list.isNotEmpty) {
        _categories = list.map((c) => Category(id: c['id'] ?? 0, name: c['name'] ?? '')).toList();
        _categories.sort((a, b) => a.name.compareTo(b.name));
        notifyListeners();
      }
    });
  }

  Future<void> fetchCategories() async {
    _setLoading(true);
    _error = null;
    try {
      final endpoints = [
        '/super/categories',
        '/categories',
        '/user/categories',
        '/complaints/categories',
      ];

      Response? response;
      String? lastError;
      for (var endpoint in endpoints) {
        try {
          debugPrint("Attempting to fetch categories from: $endpoint");
          response = await _apiService.get(endpoint);
          if (response.statusCode == 200) {
            final dynamic data = response.data;
            if (data != null && (data is List && data.isNotEmpty || data is Map && data.isNotEmpty)) {
               debugPrint("Successfully fetched valid categories from: $endpoint");
               break; 
            } else {
               debugPrint("Endpoint $endpoint returned 200 but empty data. Trying next...");
            }
          }
        } catch (e) {
          lastError = e.toString();
          debugPrint("Failed to fetch from $endpoint: $e");
        }
      }

      if (response != null && response.statusCode == 200) {
        final dynamic data = response.data;
        debugPrint("Categories Raw Data: $data");
        
        if (data == null || (data is String && data.isEmpty)) {
          debugPrint("Fetch Categories: Empty body received");
          _categories = [];
          notifyListeners();
          _setLoading(false);
          return;
        }
        
        List<dynamic> list = [];
        if (data is List) {
          list = data;
        } else if (data is Map) {
          // Comprehensive check for common wrapper keys
          final possibleKeys = ['categories', 'data', 'results', 'list', 'items'];
          for (var key in possibleKeys) {
            if (data.containsKey(key) && data[key] is List) {
              list = data[key] as List;
              break;
            }
          }
          // If still empty and no key matched, but it's a map, it might be a single object or invalid
          if (list.isEmpty && data.isNotEmpty) {
             debugPrint("Map received but no standard list key found: $data");
          }
        }
        
        _categories = list.map((c) => Category.fromJson(c)).toList();
        notifyListeners();
      } else {
        _error = lastError?.contains('SocketException') == true ? "Network Unreachable" : "Server Error";
      }
    } catch (e) {
      debugPrint("Fetch Categories Error: $e");
      _error = "Parsing Error: ${e.toString()}";
    }
    _setLoading(false);
  }

  Future<void> fetchUserComplaints(int userId) async {
    _setLoading(true);
    _error = null;
    debugPrint("Fetching complaints for User ID: $userId"); // Debug log

    try {
      final response = await _apiService.get('/complaints/my', queryParameters: {'user_id': userId});
      if (response.statusCode == 200) {
        final dynamic data = response.data;
        debugPrint("User Complaints Raw Data: $data");
        
        if (data == null) {
          _complaints = [];
          notifyListeners();
          _setLoading(false);
          return;
        }

        List<dynamic> list = [];
        if (data is List) {
          list = data;
        } else if (data is Map) {
          final possibleKeys = ['complaints', 'data', 'results', 'list', 'items'];
          for (var key in possibleKeys) {
            if (data.containsKey(key) && data[key] is List) {
              list = data[key] as List;
              break;
            }
          }
        }

        _complaints = list.map((c) => Complaint.fromJson(c)).toList();
        notifyListeners();
      } else {
        _error = "Server Error: ${response.statusCode}";
      }
    } catch (e) {
      debugPrint("Fetch User Complaints Error: $e");
      _error = "Format Error: ${e.toString()}";
    }
    _setLoading(false);
  }

  Future<void> fetchAdminComplaints({int? categoryId}) async {
    _setLoading(true);
    _error = null;
    try {
      final query = categoryId != null ? {'category_id': categoryId} : null;
      final response = await _apiService.get('/admins/complaints', queryParameters: query);
      if (response.statusCode == 200) {
        final dynamic data = response.data;
        debugPrint("Admin Complaints Raw Data: $data");
        
        if (data == null) {
          _complaints = [];
          notifyListeners();
          _setLoading(false);
          return;
        }

        List<dynamic> list = [];
        if (data is List) {
          list = data;
        } else if (data is Map) {
          final possibleKeys = ['complaints', 'data', 'results', 'list', 'items'];
          for (var key in possibleKeys) {
            if (data.containsKey(key) && data[key] is List) {
              list = data[key] as List;
              break;
            }
          }
        }

        _complaints = list.map((c) => Complaint.fromJson(c)).toList();
        notifyListeners();
      } else {
        _error = "Server Error: ${response.statusCode}";
      }
    } catch (e) {
      debugPrint("Fetch Admin Complaints Error: $e");
      _error = "Parse Error: ${e.toString()}";
    }
    _setLoading(false);
  }

  Future<void> fetchAllComplaints() async {
    _setLoading(true);
    _error = null;
    try {
      final response = await _apiService.get('/super/complaints');
      if (response.statusCode == 200) {
        final dynamic data = response.data;
        debugPrint("Super All Complaints Raw Data: $data");
        
        if (data == null) {
          _complaints = [];
          notifyListeners();
          _setLoading(false);
          return;
        }

        List<dynamic> list = [];
        if (data is List) {
          list = data;
        } else if (data is Map) {
          final possibleKeys = ['complaints', 'data', 'results', 'list', 'items'];
          for (var key in possibleKeys) {
            if (data.containsKey(key) && data[key] is List) {
              list = data[key] as List;
              break;
            }
          }
        }

        _complaints = list.map((c) => Complaint.fromJson(c)).toList();
        notifyListeners();
      } else {
        _error = "Server Error: ${response.statusCode}";
      }
    } catch (e) {
      debugPrint("Fetch All Complaints Error: $e");
      _error = "Parse Error: ${e.toString()}";
    }
    _setLoading(false);
  }

  Future<bool> submitComplaint(
    int categoryId, 
    String title, 
    String description, 
    int userId, {
    List<String> mediaUrls = const [],
    List<String> mediaTypes = const [],
  }) async {
    _setLoading(true);
    _error = null;
    debugPrint("Submitting complaint for User ID: $userId with ${mediaUrls.length} media files");
    try {
      final response = await _apiService.post('/complaints', data: {
        'user_id': userId,
        'category_id': categoryId,
        'title': title,
        'description': description,
        'media_urls': mediaUrls.join(','),
        'media_types': mediaTypes.join(','),
      });
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final dynamic data = response.data;
        if (data is Map && data.containsKey('error')) {
          _error = "Server Error: ${data['error']}";
          debugPrint("Submit Complaint Failed: ${_error}");
        } else {
          debugPrint("Complaint submitted successfully. Response: $data");
          await fetchUserComplaints(userId);
          _setLoading(false);
          return true;
        }
      } else {
        _error = "Server rejected: ${response.statusCode}";
      }
    } catch (e) {
      debugPrint("Submit Complaint Error: $e");
      _error = e.toString();
    }
    _setLoading(false);
    return false;
  }

  Future<Category?> addCategory(String name) async {
    _setLoading(true);
    _error = null;
    try {
      final endpoints = ['/categories/add', '/super/categories'];
      Response? response;
      String? lastError;

      for (var endpoint in endpoints) {
        try {
          debugPrint("Attempting to add category via: $endpoint");
          response = await _apiService.post(endpoint, data: {'name': name});
          if (response.statusCode == 201 || response.statusCode == 200) {
            debugPrint("Successfully added category via: $endpoint");
            break;
          }
        } catch (e) {
          lastError = e.toString();
          debugPrint("Failed to add category via $endpoint: $e");
        }
      }

      if (response != null && (response.statusCode == 201 || response.statusCode == 200)) {
        if (response.data == null || (response.data is String && response.data.isEmpty)) {
          debugPrint("Category added but empty body received. Re-fetching list...");
          await fetchCategories();
          _setLoading(false);
          return _categories.isNotEmpty ? _categories.last : Category(id: 0, name: name);
        }
        final newCat = Category.fromJson(response.data);
        _categories.add(newCat);
        _categories.sort((a, b) => a.name.compareTo(b.name));
        
        // Push to Firestore for cross-device sync
        ChatService().syncCategories(_categories);
        
        notifyListeners();
        _setLoading(false);
        return newCat;
      } else {
        _error = lastError?.contains('SocketException') == true ? "Network Unreachable" : "Server rejected request";
      }
    } catch (e) {
      debugPrint("Add Category Error: $e");
      _error = e.toString();
    }
    _setLoading(false);
    return null;
  }

  Future<String?> addResponse(int complaintId, String text, String status, int adminId) async {
    try {
      // The backend reference uses strpos for '/response'. Let's use a simpler path to be safe.
      final response = await _apiService.post('/response', data: {
        'complaint_id': complaintId,
        'admin_id': adminId,
        'text': text,
        'status': status.toLowerCase(),
      });
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Double check for PHP "error" in 200 response body
        if (response.data is Map && response.data.containsKey('error')) {
          return "Server Error: ${response.data['error']}";
        }

        // Manually update the status in the local list for immediate reflection
        final index = _complaints.indexWhere((c) => c.id == complaintId);
        if (index != -1) {
          final old = _complaints[index];
          _complaints[index] = Complaint(
            id: old.id,
            title: old.title,
            description: old.description,
            status: status,
            categoryName: old.categoryName,
            categoryId: old.categoryId,
            userUsername: old.userUsername,
            userId: old.userId,
            createdAt: old.createdAt,
            responses: [...old.responses],
            mediaUrls: old.mediaUrls,
            mediaTypes: old.mediaTypes,
          );
          notifyListeners();
        }
        
        // Re-fetch to get the actual backend state and nested responses
        await fetchAdminComplaints();
        return null; // Success (no error)
      } else {
        return "Server rejected: ${response.statusCode}";
      }
    } catch (e) {
      debugPrint("Add Response Error: $e");
      if (e is DioException) {
        debugPrint("Response Body: ${e.response?.data}");
        if (e.response?.data is Map) {
          final errBody = e.response!.data as Map;
          if (errBody.containsKey('error')) return "DB Error: ${errBody['error']}";
        }
        return "Network Error: ${e.message}";
      }
      return e.toString();
    }
  }
}