import 'package:flutter/material.dart';
import 'package:complaints_app/services/api_service.dart';
import 'package:complaints_app/models/app_models.dart';
import '../services/chat_service.dart';
import '../models/chat_models.dart';
import 'package:dio/dio.dart';
import 'dart:async';

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _role;
  bool _isLoading = false;
  bool _isInitialized = false;
  final ApiService _apiService = ApiService();
  StreamSubscription? _roleSubscription;

  User? get user => _user;
  String? get role => _role;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _user != null;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void startRoleListener() {
    _roleSubscription?.cancel();
    if (_user == null || _user!.id == 0) return;
    
    debugPrint("Starting real-time role listener for user: ${_user!.id}");
    _roleSubscription = ChatService().watchUser(_user!.id.toString()).listen((data) {
      if (data != null && data['role'] != null) {
        String newRole = data['role'].toString().toLowerCase();
        if (newRole == 'super_admin' || newRole == 'super') newRole = 'super admin';
        
        if (_role != newRole) {
          debugPrint('ROLE SYNC: Role updated from Firestore: $_role -> $newRole');
          _role = newRole;
          _user = User(
            id: _user!.id,
            username: _user!.username,
            email: _user!.email,
            role: newRole,
            categoryId: data['category_id'] != null ? int.tryParse(data['category_id'].toString()) : _user!.categoryId,
          );
          notifyListeners();
        }
      }
    });
  }



  Future<bool> login(String username, String password, String role) async {
    _setLoading(true);
    try {
      // Clear previous session cookies to ensure a fresh login
      await _apiService.clearCookies();
      
      String path = '';
      String roleNorm = role.toLowerCase();
      if (roleNorm == 'user') path = '/users/login';
      else if (roleNorm == 'admin') path = '/admins/login';
      else if (roleNorm == 'super' || roleNorm == 'super admin') path = '/super/login';
      else path = '/login';

      final response = await _apiService.post(path, data: {
        'username': username,
        'password': password,
      });

      if (response.statusCode == 200) {
        if (response.data == null || (response.data is String && response.data.isEmpty)) {
          debugPrint("Login success with empty body, creating placeholder user");
          _user = User(username: username, role: role, id: 0); // Placeholder
          _role = role;
          _setLoading(false);
          return true;
        }
        String roleNorm = role.toLowerCase();
        if (roleNorm.contains('super')) roleNorm = 'super';
        
        _user = User.fromJson(response.data);
        _role = _user?.role.toLowerCase() ?? roleNorm;
        if (_role == 'super_admin' || _role == 'super') _role = 'super admin';
        
        // Start watching for role changes (e.g. promotion by super admin)
        startRoleListener();
        
        _setLoading(false);
        return true;
      }
    } catch (e) {
      debugPrint("Login Error: $e");
    }
    _setLoading(false);
    return false;
  }

  Future<bool> fetchProfile() async {
    _setLoading(true);
    try {
      final endpoints = ['/me', '/profile', '/user/profile', '/users/profile'];
      Response? response;

      for (var endpoint in endpoints) {
        try {
          debugPrint("Attempting to fetch profile from: $endpoint");
          response = await _apiService.get(endpoint);
          if (response.statusCode == 200 && response.data != null) {
            debugPrint("Successfully fetched profile from: $endpoint");
            break;
          }
        } catch (e) {
          debugPrint("Profile fetch failed for $endpoint: $e");
        }
      }

      if (response != null && response.statusCode == 200 && response.data != null) {
        if (response.data is String && (response.data as String).isEmpty) {
          debugPrint("Profile fetch returned empty body, treating as unauthenticated");
          return false;
        }
        _user = User.fromJson(response.data);
        // Ensure role is preserved or updated correctly
        if (_user != null) {
           _role = _user!.role.toLowerCase();
           
           // Ensure role listener is active
           startRoleListener();
           
           notifyListeners();
           _setLoading(false);
           return true;
        }
      }
    } catch (e) {
      debugPrint("Fetch Profile Error: $e");
    } finally {
      debugPrint("FETCH PROFILE COMPLETE: Setting isInitialized to true");
      _isInitialized = true;
      _setLoading(false);
    }
    return false;
  }

  Future<String?> register(String username, String password, String email) async {
    _setLoading(true);
    try {
      final response = await _apiService.post('/users/register', data: {
        'username': username,
        'password': password,
        'email': email,
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        _setLoading(false);
        return null; // Success
      }
    } on DioException catch (e) {
      debugPrint("Register Error: $e");
      String? errorMessage;
      if (e.response?.data is Map) {
        errorMessage = e.response?.data['error'] ?? e.response?.data['message'];
      }
      _setLoading(false);
      return errorMessage ?? e.message ?? "Connection Error";
    } catch (e) {
      debugPrint("Register Error: $e");
      _setLoading(false);
      return e.toString();
    }
    _setLoading(false);
    return "Registration failed (Code: ${_isLoading ? 'Timeout' : 'Unknown Error'})";
  }

  Future<void> logout() async {
    _roleSubscription?.cancel();
    try {
      await _apiService.post('/logout');
    } catch (e) {
      debugPrint("Logout Error: $e");
    }
    _user = null;
    _role = null;
    await _apiService.clearCookies();
    notifyListeners();
  }

  // ==================== SUPER ADMIN MANAGEMENT ====================

  Future<bool> promoteUser(User targetUser, [int? categoryId]) async {
    try {
      // Prioritize local Firestore update so UI is fast and independent of backend logic issues
      await ChatService().registerUser(ChatParticipant(
        id: targetUser.id.toString(),
        name: targetUser.username,
        email: targetUser.email ?? '',
        role: 'admin',
        categoryId: (categoryId ?? 1).toString(),
      ));

      try {
        final response = await _apiService.post('/super/admins', data: {
          'username': targetUser.username,
          'id': targetUser.id,
          'category_id': categoryId ?? 1,
          'promote': true,
        });
        debugPrint("Promote Response Status: ${response.statusCode}");
      } on DioException catch (de) {
        debugPrint("Promote Backend Sync Error (Expected if user exists): ${de.response?.data ?? de.message}");
        // We continue because Firestore handles the real-time role change
      }

      _setLoading(false);
      return true; 
    } catch (e) {
      debugPrint("Promote Error: $e");
    }
    _setLoading(false);
    return false;
  }

  Future<bool> demoteUser(User targetUser) async {
    try {
      await ChatService().registerUser(ChatParticipant(
        id: targetUser.id.toString(),
        name: targetUser.username,
        email: targetUser.email ?? '',
        role: 'user',
        categoryId: '0',
      ));

      try {
        final response = await _apiService.post('/super/admins', data: {
          'username': targetUser.username,
          'id': targetUser.id,
          'promote': false,
        });
        debugPrint("Demote Response Status: ${response.statusCode}");
      } on DioException catch (de) {
        debugPrint("Demote Backend Sync Error: ${de.response?.data ?? de.message}");
      }
      
      _setLoading(false);
      return true;
    } catch (e) {
      debugPrint("Demote Error: $e");
    }
    _setLoading(false);
    return false;
  }

  Future<bool> suspendUser(User targetUser, bool suspend) async {
    _setLoading(true);
    try {
      final response = await _apiService.post('/super/users/suspend', data: {
        'username': targetUser.username,
        'id': targetUser.id,
        'suspend': suspend,
      });
      debugPrint("Suspend Response Status: ${response.statusCode}");
      debugPrint("Suspend Response Data: ${response.data}");
      if (response.statusCode == 200) {
        final currentParticipantDoc = await ChatService().getUser(targetUser.id.toString());
        final currentParticipant = currentParticipantDoc != null ? ChatParticipant.fromMap(currentParticipantDoc) : null;
        
        await ChatService().registerUser(ChatParticipant(
          id: targetUser.id.toString(),
          name: targetUser.username,
          email: targetUser.email ?? '',
          role: suspend ? 'suspended' : (currentParticipant?.prevRole ?? targetUser.role),
          prevRole: suspend ? (targetUser.role == 'suspended' ? currentParticipant?.prevRole : targetUser.role) : currentParticipant?.prevRole,
        ));
        _setLoading(false);
        return true;
      }
    } catch (e) {
      debugPrint("Suspend Error: $e");
    }
    _setLoading(false);
    return false;
  }

  Future<bool> removeUser(User targetUser) async {
    _setLoading(true);
    try {
      final response = await _apiService.post('/super/users/delete', data: {
        'username': targetUser.username,
        'id': targetUser.id,
      });
      if (response.statusCode == 200) {
        // Potentially remove from Firebase if desired
        _setLoading(false);
        return true;
      }
    } catch (e) {
      debugPrint("Remove User Error: $e");
    }
    _setLoading(false);
    return false;
  }
}