import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class CustomLongPressDraggable<T extends Object> extends StatefulWidget {
  final T data;
  final Widget child;
  final Widget feedback;
  final Widget childWhenDragging;
  final Duration longPressDuration;

  const CustomLongPressDraggable({
    Key? key,
    required this.data,
    required this.child,
    required this.feedback,
    required this.childWhenDragging,
    this.longPressDuration = const Duration(milliseconds: 300),
  }) : super(key: key);

  @override
  _CustomLongPressDraggableState<T> createState() =>
      _CustomLongPressDraggableState<T>();
}

class _CustomLongPressDraggableState<T extends Object>
    extends State<CustomLongPressDraggable<T>> {
  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: <Type, GestureRecognizerFactory>{
        LongPressGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
          () => LongPressGestureRecognizer(
            duration: widget.longPressDuration, // Correct parameter name
          ),
          (LongPressGestureRecognizer instance) {
            instance.onLongPress = _handleLongPress;
          },
        ),
      },
      behavior: HitTestBehavior.opaque,
      child: Draggable<T>(
        data: widget.data,
        feedback: widget.feedback,
        childWhenDragging: widget.childWhenDragging,
        child: widget.child,
      ),
    );
  }

  void _handleLongPress() {
    // This callback triggers the draggable; nothing extra is needed.
  }
}
