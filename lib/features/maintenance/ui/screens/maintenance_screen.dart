import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/translations/app_locale_keys.dart';
import '../../../../core/services/api_service.dart';
import 'package:mihrab/features/auth/ui/widgets/auth_background.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  bool _isChecking = false;

  Future<void> _checkStatus() async {
    setState(() => _isChecking = true);
    
    // Simulate delay for better UX
    await Future.delayed(const Duration(seconds: 1));
    
    try {
      final settings = await ApiService.getAppSettings();
      final isMaintenance = settings['maintenance_mode'] == '1' || settings['maintenance_mode'] == 'true';
    
      if (mounted) {
        setState(() => _isChecking = false);
        if (!isMaintenance) {
          // Restart app (or go to main) if maintenance is over
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocaleKeys.stillUnderMaintenance.tr, textAlign: TextAlign.right),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isChecking = false);
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Text('${AppLocaleKeys.connectionErrorPrefix.tr} $e', textAlign: TextAlign.right),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AuthBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon with pulse effect
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1.0),
                    duration: const Duration(seconds: 2),
                    curve: Curves.easeInOut,
                    builder: (context, value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    onEnd: () {}, // Repeat logic could be added here if needed
                    child: Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.orange.withOpacity(0.5), width: 2),
                      ),
                      child: const Icon(Icons.construction_rounded, size: 80, color: Colors.orange),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  Text(
                    AppLocaleKeys.maintenanceTitle.tr,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    AppLocaleKeys.maintenanceDescription.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  
                  const SizedBox(height: 50),
                  
                  _isChecking
                      ? const CircularProgressIndicator(color: Colors.orange)
                      : SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _checkStatus,
                            icon: const Icon(Icons.refresh, color: Colors.white),
                            label: Text(
                              AppLocaleKeys.refreshStatus.tr,
                              style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                        ),
                        
                  const SizedBox(height: 20),
                  
                  TextButton(
                    onPressed: () => SystemNavigator.pop(),
                    child: Text(
                      AppLocaleKeys.closeApp.tr,
                      style: TextStyle(color: Colors.white.withOpacity(0.6)),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
