import 'package:dio/dio.dart';

import '../config.dart';
import '../storage/token_store.dart';

/// Client HTTP unique de l'application.
///
/// · Injecte le jeton Bearer sur chaque requête.
/// · Sur 401 : tente un refresh, rejoue la requête ; sinon purge la session
///   et notifie les auditeurs (redirection vers l'écran de connexion).
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: kApiBaseUrl,
      connectTimeout: const Duration(milliseconds: kConnectTimeoutMs),
      receiveTimeout: const Duration(milliseconds: kReceiveTimeoutMs),
      headers: {'Accept': 'application/json'},
      validateStatus: (s) => s != null && s < 500, // géré manuellement au-delà
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokens.readAccess();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final status = error.response?.statusCode;
        final url = error.requestOptions.path;
        final isTokenEndpoint =
            url.contains('/api/token/') || url.contains('/api/token/refresh/');

        if (status == 401 && !isTokenEndpoint) {
          final refreshed = await _tryRefresh();
          if (refreshed != null) {
            // Rejoue la requête initiale avec le nouveau jeton.
            final response = await _retry(error.requestOptions, refreshed);
            return handler.resolve(response);
          }
          await _tokens.clearSession();
          onSessionExpired?.call();
        }
        handler.next(error);
      },
    ));
  }

  static final ApiClient instance = ApiClient._internal();

  late final Dio _dio;
  final TokenStore _tokens = TokenStore();
  final Dio _refreshDio = Dio(BaseOptions(baseUrl: kApiBaseUrl));

  /// Callback global (posé par AuthProvider) : déclenche la déconnexion UI.
  void Function()? onSessionExpired;

  Dio get dio => _dio;

  /// Rafraîchit le jeton d'accès ; renvoie le nouveau jeton ou null.
  Future<String?> _tryRefresh() async {
    final refresh = await _tokens.readRefresh();
    if (refresh == null) return null;
    try {
      final res = await _refreshDio.post(
        '/api/token/refresh/',
        data: {'refresh': refresh},
      );
      if (res.statusCode == 200 && res.data is Map) {
        final access = (res.data as Map)['access'] as String?;
        final newRefresh = (res.data as Map)['refresh'] as String?;
        if (access != null) {
          await _tokens.updateAccess(access);
          if (newRefresh != null) {
            // Rotation : le backend renvoie parfois un nouveau refresh.
            await _tokens.saveSession(access: access, refresh: newRefresh);
          }
          return access;
        }
      }
    } catch (_) {
      // refresh expiré → session terminée.
    }
    return null;
  }

  Future<Response<dynamic>> _retry(
    RequestOptions requestOptions,
    String token,
  ) async {
    requestOptions.headers['Authorization'] = 'Bearer $token';
    return _dio.fetch<dynamic>(requestOptions);
  }

  /// Extrait un message d'erreur lisible (erreurs de validation DRF incluses).
  static String messageOf(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final flat = data.values
            .expand<Object>((v) => v is List ? v : [v])
            .join(' ')
            .trim();
        if (flat.isNotEmpty) return flat;
        if ((data['detail'] ?? '') is String && data['detail'] != null) {
          return data['detail'] as String;
        }
      }
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return 'Connexion au serveur impossible. Vérifiez le réseau ou l\'IP dans lib/core/config.dart.';
        default:
          return 'Erreur réseau (${error.response?.statusCode ?? '—'})';
      }
    }
    return 'Erreur inattendue.';
  }
}
