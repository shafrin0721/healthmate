import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _goToDashboard(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("HealthMate Login")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GoogleLoginButton(onSuccess: () => _goToDashboard(context)),
            const SizedBox(height: 16),
            AppleLoginButton(onSuccess: () => _goToDashboard(context)),
            const SizedBox(height: 16),
            FacebookLoginButton(onSuccess: () => _goToDashboard(context)),
          ],
        ),
      ),
    );
  }
}

class GoogleLoginButton extends StatelessWidget {
  final VoidCallback onSuccess;
  const GoogleLoginButton({super.key, required this.onSuccess});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final provider = Provider.of<AuthProvider>(context, listen: false);
        await provider.signInWithGoogle();
        onSuccess();
      },
      child: const Text("Continue with Google"),
    );
  }
}

class AppleLoginButton extends StatelessWidget {
  final VoidCallback onSuccess;
  const AppleLoginButton({super.key, required this.onSuccess});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final provider = Provider.of<AuthProvider>(context, listen: false);
        await provider.signInWithApple();
        onSuccess();
      },
      child: const Text("Continue with Apple"),
    );
  }
}

class FacebookLoginButton extends StatelessWidget {
  final VoidCallback onSuccess;
  const FacebookLoginButton({super.key, required this.onSuccess});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final provider = Provider.of<AuthProvider>(context, listen: false);
        await provider.signInWithFacebook();
        onSuccess();
      },
      child: const Text("Continue with Facebook"),
    );
  }
}
