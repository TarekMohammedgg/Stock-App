import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gdrive_tutorial/core/shared_prefs.dart';
import 'package:gdrive_tutorial/core/consts.dart';
import 'package:gdrive_tutorial/features/authentication/presentation/views/login_selection_screen.dart';

class OnboardingScreen extends StatefulWidget {
  static const String id = 'onboarding_screen';
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<OnboardingData> _pages = [
    OnboardingData(
      titleKey: 'Manage Your Inventory',
      descriptionKey:
          'Keep track of all your products in one place. Add, edit, and organize your stock effortlessly.',
      imagePath: 'assets/images/onBoarding/Memory storage-bro.png',
      backgroundColor: Color(0xFF5B4FE9),
      accentColor: Color(0xFF7C6FFF),
    ),
    OnboardingData(
      titleKey: 'Smart Product Search',
      descriptionKey:
          'Find any product instantly with powerful search. Scan barcodes and access details in seconds.',
      imagePath: 'assets/images/onBoarding/sammy-line-searching.gif',
      backgroundColor: Color(0xFF6B4FE9),
      accentColor: Color(0xFF8C7FFF),
    ),
    OnboardingData(
      titleKey: 'Seamless Shopping',
      descriptionKey:
          'Process sales quickly and efficiently. Track revenue and manage your business with analytics.',
      imagePath: 'assets/images/onBoarding/sammy-line-shopping.gif',
      backgroundColor: Color(0xFF7B5FE9),
      accentColor: Color(0xFF9C8FFF),
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Fade animation controller
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Slide animation controller
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });

    // Reset and replay animations
    _fadeController.reset();
    _slideController.reset();
    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _completeOnboarding() async {
    await CacheHelper.saveData(kIsShowOnboarding, true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginSelectionScreen()),
      );
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _pages[_currentPage].backgroundColor,
                  _pages[_currentPage].backgroundColor.withOpacity(0.7),
                  _pages[_currentPage].accentColor.withOpacity(0.5),
                ],
              ),
            ),
          ),

          // Floating circles decoration
          ...List.generate(
            5,
            (index) => Positioned(
              top: (index * 150.0) % size.height,
              left: (index * 100.0) % size.width,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 600),
                opacity: 0.1,
                child: Container(
                  width: 100 + (index * 20.0),
                  height: 100 + (index * 20.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Skip button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: TextButton(
                      onPressed: _skipOnboarding,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      child: Text(
                        'Skip'.tr(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                // PageView
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: _buildPage(_pages[index]),
                        ),
                      );
                    },
                  ),
                ),

                // Page indicators
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => _buildIndicator(index),
                    ),
                  ),
                ),

                // Next/Get Started button
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _pages[_currentPage].backgroundColor,
                        elevation: 8,
                        shadowColor: Colors.black.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPage == _pages.length - 1
                                ? 'Get Started'.tr()
                                : 'Next'.tr(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _currentPage == _pages.length - 1
                                ? Icons.check_circle
                                : Icons.arrow_forward,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingData data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive sizes
        final availableHeight = constraints.maxHeight;
        final imageHeight = (availableHeight * 0.35).clamp(200.0, 280.0);
        final titleFontSize = constraints.maxWidth < 360 ? 26.0 : 28.0;
        final descFontSize = constraints.maxWidth < 360 ? 14.0 : 15.0;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: availableHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: availableHeight * 0.05),

                  // Image with hero animation effect
                  Hero(
                    tag: data.imagePath,
                    child: Container(
                      height: imageHeight,
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth * 0.85,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(data.imagePath, fit: BoxFit.contain),
                      ),
                    ),
                  ),

                  SizedBox(height: availableHeight * 0.06),

                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      data.titleKey.tr(),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),

                  SizedBox(height: availableHeight * 0.025),

                  // Description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text(
                      data.descriptionKey.tr(),
                      textAlign: TextAlign.center,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: descFontSize,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.5,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),

                  SizedBox(height: availableHeight * 0.05),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIndicator(int index) {
    final isActive = index == _currentPage;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(4),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.white.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
    );
  }
}

class OnboardingData {
  final String titleKey;
  final String descriptionKey;
  final String imagePath;
  final Color backgroundColor;
  final Color accentColor;

  OnboardingData({
    required this.titleKey,
    required this.descriptionKey,
    required this.imagePath,
    required this.backgroundColor,
    required this.accentColor,
  });
}
