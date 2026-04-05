import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/storage/secure_storage.dart';

/// Yeni kullanıcılar icin hosgeldin ekrani.
/// 4 slaytlik tanitim — bir kez gösterilir, sonra tekrar gelmez.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingPage(
      icon: Icons.school,
      title: 'OrientPro\'ya Hosgeldiniz',
      description: 'Organizasyonunuzun eğitim ve oryantasyon süreçlerini\n'
          'tek bir platformdan yonetin.',
      color: ScadaColors.cyan,
    ),
    _OnboardingPage(
      icon: Icons.route,
      title: 'Eğitim Rotalari',
      description: 'Departmaniniza ozel eğitim rotalari ile\n'
          'adim adim öğrenme sürecini takip edin.',
      color: ScadaColors.green,
    ),
    _OnboardingPage(
      icon: Icons.quiz,
      title: 'Quiz & Değerlendirme',
      description: 'Öğrendiklerinizi quiz\'ler ile test edin.\n'
          'AI destekli sorularla bilginizi olcun.',
      color: ScadaColors.amber,
    ),
    _OnboardingPage(
      icon: Icons.emoji_events,
      title: 'Rozetler & Başarılar',
      description: 'Eğitimlerinizi tamamladıkça rozet kazanın.\n'
          'Liderlik tablosunda yerinizi görüntüleyin.',
      color: ScadaColors.purple,
    ),
  ];

  Future<void> _complete() async {
    await SecureStorage.markOnboardingSeen();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/module-selection');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scada.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Atla butonu
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _complete,
                  child: Text('Atla', style: TextStyle(color: context.scada.textDim, fontSize: 15)),
                ),
              ),
            ),

            // Sayfalar
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _buildPage(_pages[i]),
              ),
            ),

            // Gostergeler ve buton
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  // Dot indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == i ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == i ? _pages[i].color : context.scada.textDim.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )),
                  ),
                  const SizedBox(height: 32),
                  // Ileri/Baslayalim butonu
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _pages.length - 1) {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _complete();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pages[_currentPage].color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _currentPage < _pages.length - 1 ? 'Devam' : 'Baslayalim!',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              color: page.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: page.color.withValues(alpha: 0.3), width: 2),
            ),
            child: Icon(page.icon, size: 56, color: page.color),
          ),
          const SizedBox(height: 40),
          Text(page.title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: context.scada.textPrimary)),
          const SizedBox(height: 16),
          Text(page.description,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: context.scada.textSecondary, height: 1.5)),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  const _OnboardingPage({required this.icon, required this.title, required this.description, required this.color});
}
