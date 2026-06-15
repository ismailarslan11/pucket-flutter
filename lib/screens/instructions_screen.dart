import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/pucket_button.dart';

class InstructionsScreen extends StatelessWidget {
  const InstructionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.6),
            radius: 1.2,
            colors: [Color(0xFF1A3A08), AppColors.bg],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 8,
                left: 8,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF888888), size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
                child: Column(
                  children: [
                    const Text(
                      'NASIL OYNANIR?',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.green,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _card('🎯 Amaç', 'Kendi renkli disklerinin tamamını rakibin sahasına geçir. Önce boşaltan kazanır!'),
                    _card('👆 Kontroller', 'Kendi yarındaki bir diski basılı tut → geri çek → bırak. Sapan gibi fırlat!'),
                    _card('🌐 Online', 'Hızlı eşleştir ile rastgele rakip bul. Ya da oda kodu ile arkadaşınla özel maç kur.'),
                    _card('🔄 İpucu', 'Karşıya geçen rakip diskini de sen fırlatabilirsin — geri yolla!'),
                    const SizedBox(height: 16),
                    PucketButton(
                      label: 'GERİ',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(String title, String body) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 360),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(body, style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 13, height: 1.6)),
        ],
      ),
    );
  }
}
