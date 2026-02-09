import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/app_models.dart';
import '../services/chat_service.dart';

class SystemProvider with ChangeNotifier {
  SystemSettings _settings = SystemSettings(
    supportNumber: 'Loading...',
    faqUrl: '#',
    helpText: 'How can we help you?',
  );
  bool _isLoading = false;
  String? _errorMessage;
  final ApiService _apiService = ApiService();

  SystemSettings get settings => _settings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void startWatchingSettings() {
    ChatService().watchSettings().listen((data) {
      if (data.isNotEmpty) {
        _settings = SystemSettings.fromJson(data);
        notifyListeners();
      }
    });
  }

  Future<void> fetchSettings() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final response = await _apiService.get('settings');
      if (response.statusCode == 200) {
        if (response.data != null && response.data is Map && (response.data as Map).isNotEmpty) {
           _settings = SystemSettings.fromJson(response.data);
        }
        // If data is null/empty, we just keep the loading/default state without error
      } else {
        _errorMessage = "Sync Issue (${response.statusCode})";
      }
    } catch (e) {
      debugPrint("Fetch Settings Error: $e");
      final err = e.toString();
      _errorMessage = err.contains('SocketException') || err.contains('Network') 
          ? "Connection Unreachable" 
          : "Server Unreachable";
    }
    _setLoading(false);
  }

  Future<bool> updateSettings(SystemSettings newSettings) async {
    _setLoading(true);
    try {
      final response = await _apiService.post('admins/settings', data: newSettings.toJson());
      if (response.statusCode == 200 || response.statusCode == 201) {
        _settings = newSettings;
        
        // Push to Firestore for cross-device sync
        ChatService().syncSettings(newSettings.toJson());
        
        notifyListeners();
        _setLoading(false);
        return true;
      }
    } catch (e) {
      debugPrint("Update Settings Error: $e");
    }
    _setLoading(false);
    return false;
  }
}