import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late Dio dio;
  late CookieJar cookieJar;
  final String baseUrl = "https://raheen.textmodify.com/api/";
  Future<void>? _initFuture;

  ApiService._internal() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
    _initFuture = _initCookieJar();
  }

  Future<void> _initCookieJar() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    cookieJar = PersistCookieJar(
      storage: FileStorage("$appDocPath/.cookies/"),
      ignoreExpires: true,
    );
    dio.interceptors.add(CookieManager(cookieJar));
  }

  Future<void> ensureInitialized() async {
    await _initFuture;
  }

  Future<Response> post(String path, {dynamic data}) async {
    await ensureInitialized();
    try {
      // Ensure path starts with / for PHP backend compatibility
      final normalizedPath = path.startsWith('/') ? path : '/$path';
      return await dio.post('api.php', 
        queryParameters: {'route': normalizedPath}, 
        data: data
      );
    } on DioException catch (e) {
      rethrow;
    }
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    await ensureInitialized();
    try {
      // Ensure path starts with / for PHP backend compatibility
      final normalizedPath = path.startsWith('/') ? path : '/$path';
      final Map<String, dynamic> params = {'route': normalizedPath};
      if (queryParameters != null) {
        params.addAll(queryParameters);
      }
      return await dio.get('api.php', 
        queryParameters: params
      );
    } on DioException catch (e) {
      rethrow;
    }
  }

  Future<void> clearCookies() async {
    await cookieJar.deleteAll();
  }
}