import 'dart:math';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SSO Example',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SSO Example')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const SsoPage()));
          },
          child: const Text('Login with SSO'),
        ),
      ),
    );
  }
}

class SsoPage extends StatefulWidget {
  const SsoPage({super.key});

  @override
  State<SsoPage> createState() => _SsoPageState();
}

class _SsoPageState extends State<SsoPage> {
  final adfsHost = 'stfs.bosch.com';
  final adfsAuthPath = '/adfs/oauth2/authorize';
  final clientId = 'xxxxxxxx-xxxx-xxxx-xxxxxxxxxxxx';
  final redirectUrl = 'boschapp://auth';

  String state = _generateRandom(16);

  @override
  Widget build(BuildContext context) => WebViewWidget(
    controller:
        WebViewController()
          ..setBackgroundColor(Colors.white)
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onNavigationRequest: (request) {
                final url = request.url;
                debugPrint('Navigation to [$url]');
                // Only allow navigation on https://$adfsHost/*
                if (url.startsWith('https://$adfsHost')) {
                  return NavigationDecision.navigate;
                  // Handle redirect via $redirectUrl
                } else if (url.startsWith(redirectUrl)) {
                  try {
                    final token = _handleRedirect(url);
                    debugPrint('SSO login success');
                    debugPrint(token);
                  } catch (e) {
                    debugPrint('SSO login failed: [${e.toString()}]');
                  }
                  return NavigationDecision.prevent;
                }
                debugPrint('Prevent navigation to [$url]');
                return NavigationDecision.prevent;
              },
            ),
          )
          ..loadRequest(
            Uri.https(adfsHost, adfsAuthPath, {
              'client_id': clientId,
              'redirect_uri': redirectUrl,
              'response_type': 'id_token token',
              'state': state,
              'login_hint': 'TEST4ME@bosch.com',
            }),
          ),
  );

  String _handleRedirect(String authUrl) {
    final paramUrl = authUrl.split('#')[1];
    final params = Uri.splitQueryString(paramUrl);
    if (params.containsKey('error') && params.containsKey('error_description')) {
      throw Exception('${params['error']}: ${params['error_description']}');
    }
    if (!params.containsKey('access_token') || params['access_token']!.isEmpty) {
      throw Exception('export_sso_token_error');
    }
    if (!params.containsKey('state') || params['state'] != state) {
      throw Exception('export_sso_state_error');
    }
    return params['access_token']!;
  }
}

String _generateRandom(int length) {
  const randomCharset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
  return List.generate(length, (i) => randomCharset[Random.secure().nextInt(randomCharset.length)]).join();
}
