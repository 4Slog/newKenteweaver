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
  final Function(PointerDownEvent)? onPointerDown;
  final Function(PointerUpEvent)? onPointerUp;
  final bool showFeedback;

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
    this.onPointerDown,
    this.onPointerUp,
    this.showFeedback = true,
  });

  @override
  State<DraggableBlock> createState() => _DraggableBlockState();
}

class _DraggableBlockState extends State<DraggableBlock> {
  bool _isDragging = false;
  bool _isHovering = false;

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

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onDoubleTap: widget.onDoubleTap,
        child: Listener(
          onPointerDown: widget.onPointerDown,
          onPointerUp: widget.onPointerUp,
          child: Draggable<String>(
            data: widget.blockId,
            onDragStarted: _handleDragStarted,
            onDragEnd: _handleDragEnd,
            onDragUpdate: widget.onDragUpdate != null ? _handleDragUpdate : null,
            feedback: widget.showFeedback ? Material(
              elevation: 8.0,
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 200),
                child: widget.child,
              ),
            ) : const SizedBox.shrink(),
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
                      color: _isDragging
                          ? Colors.blue
                          : _isHovering
                          ? Colors.blue.withOpacity(0.5)
                          : Colors.transparent,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: _isHovering && !_isDragging
                        ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                        : null,
                  ),
                  child: widget.child,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}