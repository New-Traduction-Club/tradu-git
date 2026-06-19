import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tradu_git/ui/app_theme.dart';
import 'package:tradu_git/src/github_config.dart';
import 'package:tradu_git/src/workspace_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _oauthChannel = MethodChannel('com.tdclub.tradu_git/oauth');
  static const _browserChannel = MethodChannel('com.tdclub.tradu_git/browser');

  bool _isLoggingIn = false;
  String? _loginError;

  @override
  void initState() {
    super.initState();
    _initOAuthListener();
  }

  @override
  void dispose() {
    _oauthChannel.setMethodCallHandler(null);
    super.dispose();
  }

  void _initOAuthListener() {
    _oauthChannel.setMethodCallHandler((call) async {
      if (call.method == 'onOAuthCallback') {
        final String? url = call.arguments as String?;
        if (url != null) {
          _handleOAuthRedirect(url);
        }
      }
    });

    _oauthChannel.invokeMethod<String>('getInitialLink').then((url) {
      if (url != null) {
        _handleOAuthRedirect(url);
      }
    });
  }

  Future<void> _handleOAuthRedirect(String url) async {
    final uri = Uri.parse(url);
    final code = uri.queryParameters['code'];
    if (code == null) return;

    setState(() {
      _isLoggingIn = true;
      _loginError = null;
    });

    try {
      final token = await _exchangeCodeForToken(code);
      if (token != null) {
        final userInfo = await fetchGithubUserProfile(token);
        if (userInfo != null) {
          await ref.read(githubUserProvider.notifier).saveUserInfo(userInfo);
        }
        await ref.read(githubTokenProvider.notifier).saveToken(token);
        
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      } else {
        setState(() {
          _isLoggingIn = false;
          _loginError = 'Error al intercambiar el código por token.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoggingIn = false;
        _loginError = 'Error durante la autenticación: $e';
      });
    }
  }

  Future<String?> _exchangeCodeForToken(String code) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(Uri.parse('https://github.com/login/oauth/access_token'));
      request.headers.set('Accept', 'application/json');
      request.headers.set('Content-Type', 'application/json');
      
      final payload = {
        'client_id': githubClientId,
        'client_secret': githubClientSecret,
        'code': code,
        'redirect_uri': 'tradu-git://oauth',
      };
      
      request.write(jsonEncode(payload));
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = jsonDecode(responseBody) as Map<String, dynamic>;
        return data['access_token'] as String?;
      }
    } catch (e) {
      debugPrint('Error exchanging code: $e');
    } finally {
      client.close();
    }
    return null;
  }

  Future<void> _startOAuthFlow() async {
    if (githubClientId == 'YOUR_CLIENT_ID' || githubClientSecret == 'YOUR_CLIENT_SECRET') {
      setState(() {
        _loginError = 'Debug';
      });
      return;
    }

    final authUrl =
        'https://github.com/login/oauth/authorize?client_id=$githubClientId&redirect_uri=tradu-git://oauth&scope=repo,user';
    try {
      await _browserChannel.invokeMethod('launchBrowser', {'url': authUrl});
    } catch (e) {
      setState(() {
        _loginError = 'Error al abrir el navegador: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final token = ref.watch(githubTokenProvider);

    if (token != null && token.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopBadge(),
              const Spacer(),
              Text(
                'Tradu-Git',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                'Versión beta.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.muted,
                      height: 1.35,
                    ),
              ),
              const SizedBox(height: 40),
              if (_isLoggingIn)
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Iniciando sesión en GitHub...'),
                    ],
                  ),
                )
              else ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _startOAuthFlow,
                    icon: const Icon(Icons.login),
                    label: const Text('Iniciar Sesión con GitHub'),
                  ),
                ),
                if (_loginError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _loginError!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                ],
              ],
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppTheme.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Version 0.0.1',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.ink,
                ),
          ),
        ],
      ),
    );
  }
}
