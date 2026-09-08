import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ice_cube_app/core/constants/colors.dart';
import 'package:ice_cube_app/core/constants/dimensions.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<OnboardingSlideData> _slides = [
    OnboardingSlideData(
      title: 'Invoice Management',
      subtitle: 'Manage your billing on the go. Create, track, and share professional invoices instantly.',
      isInvoice: true,
    ),
    OnboardingSlideData(
      title: 'Distribution Analytics',
      subtitle: 'Monitor your sales revenue, loaded quantities, remaining inventory, and delivery route efficiency.',
      isInvoice: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemCount: _slides.length + 1, // +1 for the Login/PIN slide
                itemBuilder: (context, index) {
                  if (index == _slides.length) {
                    return _buildLoginSlide();
                  }
                  return _buildInfoSlide(_slides[index]);
                },
              ),
            ),
            if (_currentIndex < _slides.length) _buildNavigationControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSlide(OnboardingSlideData slide) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.containerMargin),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration / Mockup Container
          Container(
            height: 300,
            width: double.infinity,
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glowing Background Circles
                Positioned(
                  top: 20,
                  right: 20,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                // Card Mockup
                if (slide.isInvoice) _buildInvoiceMockup() else _buildAnalyticsMockup(),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.xl),
          Text(
            slide.title,
            style: GoogleFonts.manrope(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.md),
          Text(
            slide.subtitle,
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: AppColors.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceMockup() {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.ac_unit, size: 16, color: AppColors.secondary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.paidContainer,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                ),
                child: Text(
                  'PAID',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.paid,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          Container(height: 8, width: 80, color: AppColors.outlineVariant.withValues(alpha: 0.5)),
          const SizedBox(height: 4),
          Container(height: 8, width: 120, color: AppColors.outlineVariant.withValues(alpha: 0.3)),
          const SizedBox(height: AppDimensions.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: GoogleFonts.manrope(fontSize: 12, color: AppColors.onSurfaceVariant),
              ),
              Text(
                '\$1,250.00',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildAnalyticsMockup() {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today\'s Stats',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const Icon(Icons.bar_chart, size: 20, color: AppColors.secondary),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          // Donut Progress
          Center(
            child: SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      value: 0.65,
                      strokeWidth: 8,
                      backgroundColor: AppColors.surfaceContainer,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  Text(
                    '65%',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(height: 6, width: 40, color: AppColors.outlineVariant),
              Container(height: 6, width: 60, color: AppColors.primary),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLoginSlide() {
    final formKey = GlobalKey<FormState>();
    final driverIdController = TextEditingController(text: 'ahmad');
    final passwordController = TextEditingController(text: '1234');

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.containerMargin,
          vertical: AppDimensions.xl,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: AppDimensions.md),
              // Brand Logo & Header
              Container(
                width: 80,
                height: 80,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      blurRadius: 10,
                    )
                  ],
                ),
                child: Image.asset('assets/images/logo.png'),
              ),
              const SizedBox(height: AppDimensions.lg),
              Text(
                'Fawares Al Sham',
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'Ice Flow Delivery Portal',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppDimensions.xl),

              // Inputs
              TextFormField(
                controller: driverIdController,
                decoration: const InputDecoration(
                  labelText: 'Driver ID',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Please enter Driver ID' : null,
              ),
              const SizedBox(height: AppDimensions.md),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'PIN / Passcode',
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Please enter Passcode' : null,
              ),
              const SizedBox(height: AppDimensions.xl),

              // Submit Button
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    context.go('/dashboard');
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                ),
                child: const Text('Login'),
              ),
              const SizedBox(height: AppDimensions.md),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Offline Mode Activated',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationControls() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.containerMargin),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Skip
            TextButton(
              onPressed: () {
                _pageController.animateToPage(
                  2,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Text(
                'Skip',
                style: GoogleFonts.manrope(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Indicators
            Row(
              children: List.generate(
                3,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentIndex == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentIndex == index ? AppColors.primary : AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            // Next
            ElevatedButton(
              onPressed: () {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                minimumSize: const Size(80, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Row(
                children: [
                  Text('Next'),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingSlideData {
  final String title;
  final String subtitle;
  final bool isInvoice;

  OnboardingSlideData({
    required this.title,
    required this.subtitle,
    required this.isInvoice,
  });
}
