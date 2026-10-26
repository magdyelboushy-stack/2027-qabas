import 'package:flutter/material.dart';
import '../../data/models/shaykh.dart';
import '../../data/models/mushaf_category.dart';
import '../../../../core/services/api_service.dart'; // ✅ Corrected path
import '../../data/recitation_service.dart';
import 'quran_view_screen.dart';

class SeriesDetailScreen extends StatefulWidget {
  final Shaykh shaykh;
  final MushafCategory series;

  const SeriesDetailScreen({
    super.key,
    required this.shaykh,
    required this.series,
  });

  @override
  State<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends State<SeriesDetailScreen> {
  // Mock data for now until API is ready
  List<MushafCategory> _subCollections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSeriesContent();
  }

  Future<void> _loadSeriesContent() async {
    try {
      final data =
          await ApiService.getSeriesContent(widget.shaykh.id, widget.series.id);

      if (mounted) {
        if (data.isEmpty) {
          // If no sub-folders, check if this "Series" contains direct audio files (Recitations)
          final recitations = await RecitationService.getRecitationsForShaykh(
              widget.shaykh.id,
              mushafId: widget.series.id);

          if (recitations.isNotEmpty && mounted) {
            // It's actually a Mushaf/Playlist, redirect to QuranViewScreen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (ctx) => QuranViewScreen(
                  shaykh: widget.shaykh,
                  mushafId: widget.series.id,
                  mushafName: widget.series.name,
                ),
              ),
            );
            return;
          }
        }

        setState(() {
          _subCollections = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Show error
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final accentColor = isDark ? Colors.cyanAccent : const Color(0xFF00695C);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF071814) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(widget.series.name,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: accentColor))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _subCollections.length,
              itemBuilder: (context, index) {
                final item = _subCollections[index];
                return _buildSeriesItem(context, item, isDark, accentColor);
              },
            ),
    );
  }

  Widget _buildSeriesItem(BuildContext context, MushafCategory item,
      bool isDark, Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: accentColor.withOpacity(0.3)),
      ),
      child: ListTile(
        onTap: () {
          if (item.isSeries) {
            // Recursive navigation for nested folders
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (ctx) => SeriesDetailScreen(
                  shaykh: widget.shaykh,
                  series: item,
                ),
              ),
            );
          } else {
            // Play content
            // Assuming non-series items are playable "Mushafs" (or single episodes)
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (ctx) => QuranViewScreen(
                  shaykh: widget.shaykh,
                  mushafId: item.id,
                  mushafName: item.name, // ✅ Pass name
                  // TODO: Pass flag to player to know this is a Lesson/Episode, not full Quran
                  // isLesson: true
                ),
              ),
            );
          }
        },
        leading: Icon(
          item.isSeries
              ? Icons.folder_open_rounded
              : Icons.play_circle_outline_rounded,
          color: accentColor,
          size: 28,
        ),
        title: Text(item.name,
            style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold)),
        subtitle: item.totalSizeGB > 0
            ? Text("${item.totalSizeGB.toStringAsFixed(2)} جيجا",
                style: TextStyle(color: accentColor, fontSize: 12))
            : (item.totalSizeMB > 0
                ? Text("${item.totalSizeMB.toStringAsFixed(2)} ميجابايت",
                    style: TextStyle(color: accentColor, fontSize: 12))
                : null),
        trailing:
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
      ),
    );
  }
}
