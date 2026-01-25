import 'package:flutter/material.dart';

class ColorUtils {
  /// Converts a hex color string to a Flutter Color object.
  /// Supports formats: #RRGGBB, #AARRGGBB, RRGGBB, AARRGGBB
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    
    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      // Fallback to a default color if parsing fails
      return Colors.blueAccent;
    }
  }
}
