import 'package:flutter/material.dart';

import 'qcf_mushaf_screen.dart';
import '../../../../core/quran/quran_compat.dart';

class MushafScreen extends StatelessWidget {
  final int initialPage;
  final AyahModel? initialAyah;
  final VoidCallback? onBack;

  const MushafScreen({
    super.key,
    this.initialPage = 1,
    this.initialAyah,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final page = initialAyah?.page ?? initialPage;
    return QcfMushafScreen(initialPage: page);
  }
}
