import 'dart:async';

import 'package:flutter/material.dart';

import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _cloudController;
  late AnimationController _textController;
  late Animation<double> _logoAnimation;
  late Animation<double> _cloudAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;

  @override
  void initState() {
    super.initState();

    // Logo animation
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    // Cloud animation
    _cloudController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _cloudAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cloudController,
      curve: Curves.easeInOut,
    ));

    // Text animation
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));
    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
    ));

    // Start animations
    _logoController.forward();
    _cloudController.forward();

    // Start text animation after logo animation
    Future.delayed(const Duration(milliseconds: 800), () {
      _textController.forward();
    });

    // Navigate to login screen after 3 seconds
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _cloudController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Cloud element at bottom - sampai ke bawah
          Positioned(
            bottom: 5, // Ubah dari 0 ke 20 agar lebih ke atas
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _cloudAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 50 * (1 - _cloudAnimation.value)),
                  child: CustomPaint(
                    size: Size(MediaQuery.of(context).size.width, 200),
                    painter: CloudPainter(),
                  ),
                );
              },
            ),
          ),

          // Logo in center - dipindah lebih ke atas
          Center(
            child: AnimatedBuilder(
              animation: _logoAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _logoAnimation.value,
                  child: Transform.translate(
                    offset:
                        const Offset(0, -80), // Geser ke atas dari -30 ke -80
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo circle
                        Container(
                          width: 120,
                          height: 120,
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 60,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Text "Absensi Qwords" with animation
                        SlideTransition(
                          position: _textSlideAnimation,
                          child: FadeTransition(
                            opacity: _textFadeAnimation,
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Absensi ',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  'Qwords',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Version text at bottom - tanpa padding manual
          Positioned(
            bottom:
                55, // Posisi tetap, biarkan Flutter menangani navigation bar
            left: 0,
            right: 0,
            child: Center(
              child: FadeTransition(
                opacity: _textFadeAnimation,
                child: const Text(
                  'v 1.0',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color.fromRGBO(255, 255, 255, 1),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.fill;

    final path = Path();

    // Create cloud-like shape at bottom - dibuat lebih rendah dan proporsional
    path.moveTo(0, size.height);

    // Left side curve - dibuat lebih rendah
    path.quadraticBezierTo(
      size.width * 0.1,
      size.height * 0.7, // Ubah dari 0.6 ke 0.7
      size.width * 0.2,
      size.height * 0.6, // Ubah dari 0.5 ke 0.6
    );

    // First bump - dibuat lebih rendah
    path.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.5, // Ubah dari 0.4 ke 0.5
      size.width * 0.4,
      size.height * 0.6, // Ubah dari 0.5 ke 0.6
    );

    // Second bump - dibuat lebih rendah
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.4, // Ubah dari 0.3 ke 0.4
      size.width * 0.6,
      size.height * 0.6, // Ubah dari 0.5 ke 0.6
    );

    // Third bump - dibuat lebih rendah
    path.quadraticBezierTo(
      size.width * 0.7,
      size.height * 0.5, // Ubah dari 0.4 ke 0.5
      size.width * 0.8,
      size.height * 0.6, // Ubah dari 0.5 ke 0.6
    );

    // Right side curve - dibuat lebih rendah
    path.quadraticBezierTo(
      size.width * 0.9,
      size.height * 0.7, // Ubah dari 0.6 ke 0.7
      size.width,
      size.height,
    );

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
