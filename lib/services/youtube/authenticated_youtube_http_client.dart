import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class AuthenticatedYoutubeHttpClient extends YoutubeHttpClient {
  final String cookie;

  AuthenticatedYoutubeHttpClient(this.cookie) {
    debugPrint(
      'AuthenticatedYoutubeHttpClient: constructed with cookie len=${cookie.length}, '
      'names=${cookie.split(';').map((c) => c.split('=').first.trim()).toList()}',
    );
  }

  @override
  Map<String, String> get headers => {
    ...YoutubeHttpClient.defaultHeaders,
    'cookie': cookie,
  };

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (request.url.path.contains('/watch') ||
        request.url.path.contains('/youtubei/')) {
      debugPrint(
        'AuthenticatedYoutubeHttpClient: ${request.method} ${request.url} '
        'cookie-header-present=${request.headers.containsKey('cookie') || headers.containsKey('cookie')}',
      );
    }
    return super.send(request);
  }
}
