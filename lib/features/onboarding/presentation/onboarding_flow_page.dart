import 'package:flutter/material.dart';

import '../../shell/presentation/main_shell_page.dart';

class OnboardingFlowPage extends StatefulWidget {
  const OnboardingFlowPage({super.key});

  @override
  State<OnboardingFlowPage> createState() => _OnboardingFlowPageState();
}

class _OnboardingFlowPageState extends State<OnboardingFlowPage> {
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  int _step = 0;

  @override
  void dispose() {
    _phoneController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < 3) {
      setState(() => _step++);
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShellPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _WelcomeStep(onNext: _next),
      _PhoneStep(controller: _phoneController, onNext: _next),
      _OtpStep(onNext: _next),
      _ProfileStep(
        usernameController: _usernameController,
        bioController: _bioController,
        onNext: _next,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: pages[_step],
        ),
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('welcome'),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Container(
              height: 320,
              width: double.infinity,
              color: const Color(0xFFEAD9B7),
              alignment: Alignment.bottomRight,
              child: Container(
                margin: const EdgeInsets.all(14),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFC45A12),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Handpicked',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text('e-Mall', style: TextStyle(fontSize: 46, fontWeight: FontWeight.w700, color: Color(0xFF3F2413))),
          const SizedBox(height: 12),
          const Text(
            'Discover a curated marketplace where heritage meets high-end digital shopping.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, height: 1.4, color: Color(0xFF6D513E)),
          ),
          const Spacer(),
          _PrimaryButton(label: 'Explore The Collection', onTap: onNext),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onNext,
              style: OutlinedButton.styleFrom(
                side: BorderSide.none,
                backgroundColor: const Color(0xFFF1DCCB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                padding: const EdgeInsets.symmetric(vertical: 17),
              ),
              child: const Text('Sign In', style: TextStyle(fontSize: 18, color: Color(0xFF4D2F1D), fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneStep extends StatelessWidget {
  const _PhoneStep({required this.controller, required this.onNext});

  final TextEditingController controller;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('phone'),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white,
            child: Icon(Icons.shopping_bag_outlined, color: Color(0xFFC45A12)),
          ),
          const SizedBox(height: 24),
          const Text('Welcome back', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 36, color: Color(0xFF3F2413))),
          const SizedBox(height: 12),
          const Text(
            'Enter your phone number to access your artisan collection.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Phone Number', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E4D9),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Text('NG  +234'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: '80 000 0000',
                    filled: true,
                    fillColor: const Color(0xFFF3E4D9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          _PrimaryButton(label: 'Continue', onTap: onNext),
        ],
      ),
    );
  }
}

class _OtpStep extends StatelessWidget {
  const _OtpStep({required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('otp'),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          const Text('Verification Code', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: Color(0xFF3F2413))),
          const SizedBox(height: 10),
          const Text(
            "We've sent a 6-digit code to your mobile device.",
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 26),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              6,
              (index) => Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: const Color(0xFFF3E4D9),
                ),
                child: const Center(
                  child: CircleAvatar(radius: 3.5, backgroundColor: Color(0xFF5E6574)),
                ),
              ),
            ),
          ),
          const Spacer(),
          _PrimaryButton(label: 'Verify Code', onTap: onNext),
        ],
      ),
    );
  }
}

class _ProfileStep extends StatelessWidget {
  const _ProfileStep({
    required this.usernameController,
    required this.bioController,
    required this.onNext,
  });

  final TextEditingController usernameController;
  final TextEditingController bioController;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('profile'),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          const CircleAvatar(
            radius: 46,
            backgroundColor: Color(0xFFF2DDCF),
            child: Icon(Icons.camera_alt, color: Color(0xFFC45A12)),
          ),
          const SizedBox(height: 22),
          const Text('Setup your craft', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: Color(0xFF3F2413))),
          const SizedBox(height: 12),
          const Text('Share your name and vibe with the community.'),
          const SizedBox(height: 26),
          TextField(
            controller: usernameController,
            decoration: InputDecoration(
              hintText: 'eg. NeoArtisan_24',
              filled: true,
              fillColor: const Color(0xFFF3E4D9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: bioController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Tell us about your creative journey...',
              filled: true,
              fillColor: const Color(0xFFF3E4D9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const Spacer(),
          _PrimaryButton(label: 'Finish Setup', onTap: onNext),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF26D21),
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
        child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
