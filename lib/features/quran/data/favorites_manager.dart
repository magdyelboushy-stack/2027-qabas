import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'models/recitation.dart';

/// Manages the list of favorite recitations using local storage (SharedPreferences).
class FavoritesManager {
  static const _keyFavorites = 'favorites_recitations';

  /// Loads the list of favorite recitations from local storage.
  static Future<List<Recitation>> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> favoritesJson = prefs.getStringList(_keyFavorites) ?? [];

    return favoritesJson.map((jsonString) {
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      return Recitation.fromJson(jsonMap);
    }).toList();
  }

  /// Persists the current list of favorites to local storage.
  static Future<void> _saveFavorites(List<Recitation> recitations) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> favoritesJson = recitations
        .map((recitation) => json.encode(recitation.toJson()))
        .toList();
    await prefs.setStringList(_keyFavorites, favoritesJson);
  }

  /// Adds a recitation to the favorites list if it doesn't already exist.
  static Future<void> addFavorite(BuildContext context, Recitation recitation) async {
    final currentFavorites = await loadFavorites();
    
    // Check if already exists to prevent duplicates
    if (!currentFavorites.any((s) => s.id == recitation.id)) {
      currentFavorites.add(recitation);
      await _saveFavorites(currentFavorites);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Added to favorites', textAlign: TextAlign.center))
        );
      }
    }
  }

  /// Removes a recitation from the favorites list.
  static Future<void> removeFavorite(BuildContext context, Recitation recitation) async {
    final currentFavorites = await loadFavorites();
    currentFavorites.removeWhere((s) => s.id == recitation.id);
    await _saveFavorites(currentFavorites);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from favorites', textAlign: TextAlign.center))
      );
    }
  }

  /// Checks if a specific recitation is currently marked as favorite.
  static Future<bool> isFavorite(Recitation recitation) async {
    final currentFavorites = await loadFavorites();
    return currentFavorites.any((s) => s.id == recitation.id);
  }
}
