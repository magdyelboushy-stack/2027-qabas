import 'package:flutter/material.dart';

import '../../../../core/utils/platform.dart';

class AdPopupDialog extends StatelessWidget {
  final String imageUrl;

  const AdPopupDialog({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    // Fix localhost for Android Emulator
    String fixedUrl = imageUrl;
    if (isAndroid && fixedUrl.contains('localhost')) {
      fixedUrl = fixedUrl.replaceAll('localhost', 'mihrab-app.alwaysdata.net').replaceFirst('http://', 'https://');
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(15),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(
              fixedUrl,
              fit: BoxFit.contain,
              loadingBuilder: (ctx, child, loading) {
                if (loading == null) return child;
                return Container(
                  height: 200,
                  width: double.infinity,
                  color: Colors.white,
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (ctx, err, stack) => Container(
                height: 150,
                width: double.infinity,
                color: Colors.white,
                child: const Center(child: Icon(Icons.broken_image)),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}