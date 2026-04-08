import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/tutorial_service.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_OnboardingPage> _pages = [
    _OnboardingPage(
      icon: Icons.local_gas_station_rounded,
      iconColor: Color(0xFF4CAF50),
      title: 'Track Every Fill-Up',
      description:
          'Log your fuel purchases with liters, price, and odometer readings. Never lose track of your fuel expenses again.',
      gradient: [Color(0xFF667eea), Color(0xFF764ba2)],
    ),
    _OnboardingPage(
      icon: Icons.directions_car_rounded,
      iconColor: Color(0xFF2196F3),
      title: 'Multiple Vehicles',
      description:
          'Manage your car, bike, truck, or any vehicle separately. Switch between them anytime to see individual stats.',
      gradient: [Color(0xFF2196F3), Color(0xFF21CBF3)],
    ),
    _OnboardingPage(
      icon: Icons.speed_rounded,
      iconColor: Color(0xFFFF9800),
      title: 'Smart Mileage Calculation',
      description:
          'We automatically calculate your fuel efficiency (km/L) from your odometer readings. See trends over time.',
      gradient: [Color(0xFFFF9800), Color(0xFFFFC107)],
    ),
    _OnboardingPage(
      icon: Icons.bar_chart_rounded,
      iconColor: Color(0xFFE91E63),
      title: 'Budget & Reports',
      description:
          'Set a monthly fuel budget and visualize your spending with beautiful charts. Stay in control of your costs.',
      gradient: [Color(0xFFE91E63), Color(0xFFF06292)],
    ),
    _OnboardingPage(
      icon: Icons.cloud_done_rounded,
      iconColor: Color(0xFF00BCD4),
      title: 'Backup to Cloud',
      description:
          'Sync your data securely to Google Drive. Restore anytime on any device — your fuel history is always safe.',
      gradient: [Color(0xFF00BCD4), Color(0xFF4DD0E1)],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    await TutorialService.setOnboardingCompleted(true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button (top right)
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: isLastPage ? 0 : 1,
                  child: TextButton(
                    onPressed: isLastPage ? null : _completeOnboarding,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (context, i) => _OnboardingPageView(page: _pages[i], isDark: isDark),
              ),
            ),

            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final isActive = i == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: isActive ? 28 : 8,
                  decoration: BoxDecoration(
                    color: isActive
                        ? _pages[_currentPage].gradient[0]
                        : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),

            const SizedBox(height: 32),

            // Bottom action button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: _pages[_currentPage].gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _pages[_currentPage].gradient[0].withValues(alpha: 0.4),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _nextPage,
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isLastPage ? 'Get Started' : 'Next',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isLastPage ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final List<Color> gradient;

  const _OnboardingPage({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.gradient,
  });
}

class _OnboardingPageView extends StatelessWidget {
  final _OnboardingPage page;
  final bool isDark;

  const _OnboardingPageView({required this.page, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated icon container
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: page.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: page.gradient[0].withValues(alpha: 0.45),
                        blurRadius: 40,
                        spreadRadius: 4,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Icon(
                    page.icon,
                    size: 100,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 56),

          // Title
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, (1 - value) * 20),
                  child: child,
                ),
              );
            },
            child: Text(
              page.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.exo2(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey.shade900,
                letterSpacing: 0.5,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Description
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, (1 - value) * 30),
                  child: child,
                ),
              );
            },
            child: Text(
              page.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
