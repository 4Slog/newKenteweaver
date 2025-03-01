import 'package:flutter/material.dart';

class DraggableBlock extends StatefulWidget {
  final Widget child;
  final String blockId;
  final bool isLocked;
  final VoidCallback onDragStarted;
  final void Function(DraggableDetails)? onDragEndWithDetails;
  final VoidCallback onDragEndSimple;
  final bool Function(DragTargetDetails<String>)? onWillAccept;
  final void Function(DragTargetDetails<String>)? onAccept;
  final Function(Offset)? onDragUpdate;
  final VoidCallback? onDoubleTap;

  const DraggableBlock({
    super.key,
    required this.child,
    required this.blockId,
    required this.onDragStarted,
    this.onDragEndWithDetails,
    required this.onDragEndSimple,
    this.isLocked = false,
    this.onWillAccept,
    this.onAccept,
    this.onDragUpdate,
    this.onDoubleTap,
  });

  @override
  State<DraggableBlock> createState() => _DraggableBlockState();
}

class _DraggableBlockState extends State<DraggableBlock> {
  bool _isDragging = false;

  void _handleDragEnd(DraggableDetails details) {
    setState(() {
      _isDragging = false;
    });
    widget.onDragEndWithDetails?.call(details);
    widget.onDragEndSimple();
  }
  
  void _handleDragUpdate(DragUpdateDetails details) {
    widget.onDragUpdate?.call(details.globalPosition);
  }

  void _handleDragStarted() {
    setState(() {
      _isDragging = true;
    });
    widget.onDragStarted();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLocked) {
      return widget.child;
    }

    return GestureDetector(
      onDoubleTap: widget.onDoubleTap,
      child: Draggable<String>(
        data: widget.blockId,
        onDragStarted: _handleDragStarted,
        onDragEnd: _handleDragEnd,
        onDragUpdate: widget.onDragUpdate != null ? _handleDragUpdate : null,
        feedback: Material(
          elevation: 4.0,
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 200),
            child: widget.child,
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.5,
          child: widget.child,
        ),
        child: DragTarget<String>(
          onWillAccept: (data) {
            if (widget.onWillAccept != null && data != null) {
              return widget.onWillAccept!(DragTargetDetails<String>(
                data: data,
                offset: Offset.zero,
              ));
            }
            return false;
          },
          onAccept: (data) {
            if (widget.onAccept != null) {
              widget.onAccept!(DragTargetDetails<String>(
                data: data,
                offset: Offset.zero,
              ));
            }
          },
          builder: (context, candidateData, rejectedData) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isDragging ? Colors.blue : Colors.transparent,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: widget.child,
            );
          },
        ),
      ),
    );
  }
}
