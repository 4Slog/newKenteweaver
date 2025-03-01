import 'package:flutter/material.dart';
import '../models/block_model.dart';
import '../services/unified/pattern_engine.dart';

class WeavingPatternRenderer extends StatelessWidget {
  final List<List<Color>>? patternGrid;
  final Map<String, dynamic>? patternData;
  final BlockCollection? blockCollection;
  final double cellSize;
  final bool showGrid;
  final Function(int, int)? onCellTap;

  const WeavingPatternRenderer({
    Key? key,
    this.patternGrid,
    this.patternData,
    this.blockCollection,
    this.cellSize = 20.0,
    this.showGrid = true,
    this.onCellTap,
  }) : assert(
        (patternGrid != null) || (patternData != null) || (blockCollection != null),
        'One of patternGrid, patternData, or blockCollection must be provided',
      ),
       super(key: key);

  @override
  Widget build(BuildContext context) {
    if (blockCollection != null) {
      // Generate pattern grid from block collection
      final patternEngine = PatternEngine();
      final grid = patternEngine.generatePatternFromBlocks(blockCollection!);
      
      return CustomPaint(
        size: Size(
          grid[0].length * cellSize,
          grid.length * cellSize,
        ),
        painter: WeavingPatternPainter(
          grid: grid,
          cellSize: cellSize,
          showGrid: showGrid,
        ),
        foregroundPainter: showGrid ? GridPainter(
          rowCount: grid.length,
          colCount: grid[0].length,
          cellSize: cellSize,
        ) : null,
      );
    } else if (patternGrid != null) {
      return CustomPaint(
        size: Size(
          patternGrid![0].length * cellSize,
          patternGrid!.length * cellSize,
        ),
        painter: WeavingPatternPainter(
          grid: patternGrid!,
          cellSize: cellSize,
          showGrid: showGrid,
        ),
        foregroundPainter: showGrid ? GridPainter(
          rowCount: patternGrid!.length,
          colCount: patternGrid![0].length,
          cellSize: cellSize,
        ) : null,
      );
    } else if (patternData != null) {
      // Legacy support for the old patternData format
      if (patternData!["grid"] == null || patternData!["grid"].isEmpty) {
        return const SizedBox(
          height: 300,
          child: Center(
            child: Text("No valid pattern data"),
          ),
        );
      }
      
      try {
        final rows = patternData!["grid"].length;
        final columns = patternData!["grid"][0].length;
        
        final grid = List.generate(
          rows,
          (i) => List.generate(
            columns,
            (j) {
              final colorString = patternData!["grid"][i][j] ?? "#000000";
              return Color(int.parse(colorString.replaceAll("#", "0xFF")));
            },
          ),
        );
        
        return CustomPaint(
          size: Size(columns * cellSize, rows * cellSize),
          painter: WeavingPatternPainter(
            grid: grid,
            cellSize: cellSize,
            showGrid: showGrid,
          ),
          foregroundPainter: showGrid ? GridPainter(
            rowCount: rows,
            colCount: columns,
            cellSize: cellSize,
          ) : null,
        );
      } catch (e) {
        debugPrint("❌ Error rendering pattern: $e");
        return const SizedBox(
          height: 300,
          child: Center(
            child: Text("Error rendering pattern"),
          ),
        );
      }
    }
    
    return const SizedBox(
      height: 300,
      child: Center(
        child: Text("No valid pattern data"),
      ),
    );
  }
}

class WeavingPatternPainter extends CustomPainter {
  final List<List<Color>> grid;
  final double cellSize;
  final bool showGrid;

  WeavingPatternPainter({
    required this.grid,
    required this.cellSize,
    this.showGrid = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int row = 0; row < grid.length; row++) {
      for (int col = 0; col < grid[row].length; col++) {
        paint.color = grid[row][col];
        
        canvas.drawRect(
          Rect.fromLTWH(
            col * cellSize,
            row * cellSize,
            cellSize,
            cellSize,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant WeavingPatternPainter oldDelegate) {
    return oldDelegate.grid != grid || 
           oldDelegate.cellSize != cellSize || 
           oldDelegate.showGrid != showGrid;
  }
}

class GridPainter extends CustomPainter {
  final int rowCount;
  final int colCount;
  final double cellSize;
  
  GridPainter({
    required this.rowCount,
    required this.colCount,
    required this.cellSize,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black26
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    
    // Draw horizontal grid lines
    for (int i = 0; i <= rowCount; i++) {
      canvas.drawLine(
        Offset(0, i * cellSize),
        Offset(colCount * cellSize, i * cellSize),
        paint,
      );
    }
    
    // Draw vertical grid lines
    for (int j = 0; j <= colCount; j++) {
      canvas.drawLine(
        Offset(j * cellSize, 0),
        Offset(j * cellSize, rowCount * cellSize),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return oldDelegate.rowCount != rowCount || 
           oldDelegate.colCount != colCount || 
           oldDelegate.cellSize != cellSize;
  }
}
