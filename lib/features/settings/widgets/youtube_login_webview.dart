import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../services/service_providers.dart';

const _loginUrl =
    'https://accounts.google.com/ServiceLogin?service=youtube&continue=https://www.youtube.com/';

class YoutubeLoginWebView extends ConsumerStatefulWidget {
  const YoutubeLoginWebView({super.key});

  @override
  ConsumerState<YoutubeLoginWebView> createState() => _YoutubeLoginWebViewState();
}

class _YoutubeLoginWebViewState extends ConsumerState<YoutubeLoginWebView> {
  late final WebViewController _controller;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(onPageFinished: (url) => _onPageFinished(url)),
      )
      ..loadRequest(Uri.parse(_loginUrl));
  }

  Future<void> _onPageFinished(String url) async {
    final host = Uri.tryParse(url)?.host ?? '';
    if (!host.endsWith('youtube.com') || _capturing) return;
    await _tryCaptureSession();
  }

  Future<void> _tryCaptureSession() async {
    setState(() => _capturing = true);
    try {
      final result = await _controller.runJavaScriptReturningResult(
        'document.cookie',
      );
      final cookieString = _unwrapJsString(result.toString());
      final hasSession =
          cookieString.contains('SAPISID=') ||
          cookieString.contains('LOGIN_INFO=') ||
          cookieString.contains('APISID=');
      debugPrint(
        'YoutubeLoginWebView: captured cookie names='
        '${cookieString.split(';').map((c) => c.split('=').first.trim()).toList()}, '
        'hasSession=$hasSession',
      );
      if (cookieString.isEmpty || !hasSession) {
        setState(() => _capturing = false);
        return;
      }
      await ref.read(youtubeAuthCookieProvider.notifier).signIn(cookieString);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _capturing = false);
    }
  }

  String _unwrapJsString(String raw) {
    if (raw.length >= 2 && raw.startsWith('"') && raw.endsWith('"')) {
      return raw
          .substring(1, raw.length - 1)
          .replaceAll(r'\"', '"')
          .replaceAll(r'\\', r'\');
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign in to YouTube'),
        actions: [
          IconButton(
            tooltip: "I'm signed in",
            icon: const Icon(Icons.check),
            onPressed: _capturing ? null : _tryCaptureSession,
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_capturing) const LinearProgressIndicator(),
        ],
      ),
    );
  }
}
