import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

/// Utility class to generate pattern images for the app
class PatternImageGenerator {
  /// Generate all missing pattern images
  static Future<void> generateAllPatternImages() async {
    await generateCheckerPattern();
    await generateZigzagPattern();
    await generateStripesVerticalPattern();
    await generateStripesHorizontalPattern();
    await generateSquarePattern();
    await generateDiamondsPattern();
    
    print('All pattern images generated successfully!');
  }
  
  /// Generate checker pattern image
  static Future<void> generateCheckerPattern() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = const Size(200, 200);
    final paint = Paint()
      ..color = Colors.indigo
      ..style = PaintingStyle.fill;
    
    // Draw checker pattern
    final cellSize = size.width / 4;
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        if ((i + j) % 2 == 0) {
          canvas.drawRect(
            Rect.fromLTWH(i * cellSize, j * cellSize, cellSize, cellSize),
            paint,
          );
        }
      }
    }
    
    await _saveCanvasToFile(recorder, size, 'checker_pattern.png');
  }
  
  /// Generate zigzag pattern image
  static Future<void> generateZigzagPattern() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = const Size(200, 200);
    final paint = Paint()
      ..color = Colors.purple
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    
    // Draw zigzag pattern
    final path = Path();
    path.moveTo(0, size.height / 2);
    
    final segments = 8;
    final segmentWidth = size.width / segments;
    final amplitude = size.height / 4;
    
    for (int i = 0; i < segments; i++) {
      if (i % 2 == 0) {
        path.lineTo((i + 1) * segmentWidth, size.height / 2 - amplitude);
      } else {
        path.lineTo((i + 1) * segmentWidth, size.height / 2 + amplitude);
      }
    }
    
    canvas.drawPath(path, paint);
    
    await _saveCanvasToFile(recorder, size, 'zigzag_pattern.png');
  }
  
  /// Generate vertical stripes pattern image
  static Future<void> generateStripesVerticalPattern() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = const Size(200, 200);
    final paint = Paint()
      ..color = Colors.teal
      ..style = PaintingStyle.fill;
    
    // Draw vertical stripes pattern
    final stripeWidth = size.width / 8;
    for (int i = 0; i < 8; i += 2) {
      canvas.drawRect(
        Rect.fromLTWH(i * stripeWidth, 0, stripeWidth, size.height),
        paint,
      );
    }
    
    await _saveCanvasToFile(recorder, size, 'stripes_vertical_pattern.png');
  }
  
  /// Generate horizontal stripes pattern image
  static Future<void> generateStripesHorizontalPattern() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = const Size(200, 200);
    final paint = Paint()
      ..color = Colors.lightBlue
      ..style = PaintingStyle.fill;
    
    // Draw horizontal stripes pattern
    final stripeHeight = size.height / 8;
    for (int i = 0; i < 8; i += 2) {
      canvas.drawRect(
        Rect.fromLTWH(0, i * stripeHeight, size.width, stripeHeight),
        paint,
      );
    }
    
    await _saveCanvasToFile(recorder, size, 'stripes_horizontal_pattern.png');
  }
  
  /// Generate square pattern image
  static Future<void> generateSquarePattern() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = const Size(200, 200);
    final paint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    
    // Draw square pattern
    final padding = 20.0;
    final squareSize = (size.width - 2 * padding) / 3;
    
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        canvas.drawRect(
          Rect.fromLTWH(
            padding + i * squareSize,
            padding + j * squareSize,
            squareSize,
            squareSize,
          ),
          paint,
        );
      }
    }
    
    await _saveCanvasToFile(recorder, size, 'square_pattern.png');
  }
  
  /// Generate diamonds pattern image
  static Future<void> generateDiamondsPattern() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = const Size(200, 200);
    final paint = Paint()
      ..color = Colors.pink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    
    // Draw diamonds pattern
    final cellSize = size.width / 3;
    
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        final centerX = i * cellSize + cellSize / 2;
        final centerY = j * cellSize + cellSize / 2;
        final halfSize = cellSize * 0.4;
        
        final path = Path();
        path.moveTo(centerX, centerY - halfSize); // Top
        path.lineTo(centerX + halfSize, centerY); // Right
        path.lineTo(centerX, centerY + halfSize); // Bottom
        path.lineTo(centerX - halfSize, centerY); // Left
        path.close();
        
        canvas.drawPath(path, paint);
      }
    }
    
    await _saveCanvasToFile(recorder, size, 'diamonds_pattern.png');
  }
  
  /// Save canvas to a PNG file
  static Future<void> _saveCanvasToFile(
    ui.PictureRecorder recorder,
    Size size,
    String fileName,
  ) async {
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();
    
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$fileName';
    
    final file = File(path);
    await file.writeAsBytes(buffer);
    
    // Copy to assets directory
    final assetsPath = 'assets/images/blocks/$fileName';
    final assetsFile = File(assetsPath);
    await assetsFile.writeAsBytes(buffer);
    
    print('Generated $fileName');
  }
}
