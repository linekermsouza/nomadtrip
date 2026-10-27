import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class NavigationLauncher {
  /// Opens external URL (Instagram, YouTube, websites)
  static Future<bool> openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Launch route navigation directly via Google Maps
  static Future<bool> launchGoogleMaps(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Launch route navigation directly via Waze
  static Future<bool> launchWaze(double lat, double lng) async {
    final uri = Uri.parse('https://waze.com/ul?ll=$lat,$lng&navigate=yes');
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Launch route navigation via Apple Maps
  static Future<bool> launchAppleMaps(double lat, double lng) async {
    final uri = Uri.parse('http://maps.apple.com/?daddr=$lat,$lng');
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Shows a clean bottom modal to select preferred navigation app
  static void showNavigationSheet(
    BuildContext context, {
    required String placeName,
    required double latitude,
    required double longitude,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.navigation_rounded, color: Colors.indigo),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Navigate to $placeName',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Select your preferred navigation app:',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8F0FE),
                    child: Icon(Icons.map_rounded, color: Color(0xFF1A73E8)),
                  ),
                  title: const Text(
                    'Google Maps',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Best for turn-by-turn and Florida traffic',
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    launchGoogleMaps(latitude, longitude);
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE0F7FA),
                    child: Icon(
                      Icons.directions_car_rounded,
                      color: Color(0xFF00ACC1),
                    ),
                  ),
                  title: const Text(
                    'Waze',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Real-time alerts, police & speed traps',
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    launchWaze(latitude, longitude);
                  },
                ),
                if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS)
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFF5F5F7),
                      child: Icon(Icons.apple_rounded, color: Colors.black87),
                    ),
                    title: const Text(
                      'Apple Maps',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('Native iOS navigation'),
                    onTap: () {
                      Navigator.pop(ctx);
                      launchAppleMaps(latitude, longitude);
                    },
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}
