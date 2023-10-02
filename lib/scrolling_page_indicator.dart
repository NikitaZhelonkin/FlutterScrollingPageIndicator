import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

class ScrollingPageIndicator extends StatefulWidget {
  const ScrollingPageIndicator({
    required this.itemCount,
    required this.controller,
    super.key,
    this.dotSize = 6.0,
    this.dotSelectedSize = 10.0,
    this.dotColor = Colors.grey,
    this.dotSelectedColor = Colors.blueGrey,
    this.dotSpacing = 12.0,
    this.visibleDotCount = 5,
    this.visibleDotThreshold = 2,
    this.orientation = Axis.horizontal,
    this.reverse = false,
  }) : assert(visibleDotCount % 2 != 0, 'visibleDotCount should be even');
  final double dotSize;

  final double dotSelectedSize;

  final Color dotColor;

  final Color dotSelectedColor;

  final double dotSpacing;

  final int visibleDotCount;

  final int visibleDotThreshold;

  final int itemCount;

  final PageController controller;

  final Axis orientation;

  final bool reverse;

  @override
  State<StatefulWidget> createState() {
    return _ScrollingPageIndicatorState();
  }
}

class _ScrollingPageIndicatorState extends State<ScrollingPageIndicator> {
  final Paint _paint = Paint();

  @override
  void initState() {
    widget.controller.addListener(_onController);
    super.initState();
  }

  @override
  void didUpdateWidget(ScrollingPageIndicator oldWidget) {
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_onController);
      widget.controller.addListener(_onController);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onController);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = widget.itemCount >= widget.visibleDotCount ? widget.visibleDotCount : widget.itemCount;
    final width = (itemCount - 1) * widget.dotSpacing + widget.dotSelectedSize;
    final Widget child = SizedBox(
      width: widget.orientation == Axis.horizontal ? width : widget.dotSelectedSize,
      height: widget.orientation == Axis.vertical ? width : widget.dotSelectedSize,
      child: CustomPaint(
        painter: _Painter(
          widget,
          currentPage,
          _paint,
          widget.orientation,
        ),
      ),
    );
    return IgnorePointer(
      child: child,
    );
  }

  double get currentPage {
    try {
      return widget.controller.page ?? 0.0;
    } catch (exception) {
      return 0.0;
    }
  }

  void _onController() {
    setState(() {});
  }
}

class _Painter extends CustomPainter {
  _Painter(this._widget, this._page, this._paint, this.orientation) {
    _firstDotOffset = _widget.itemCount > _widget.visibleDotCount ? 0 : _widget.dotSelectedSize / 2;
  }

  final ScrollingPageIndicator _widget;
  final double _page;
  final Paint _paint;
  final Axis orientation;

  late double _visibleFramePosition;

  late double _firstDotOffset;

  double get page {
    try {
      if (_widget.reverse) {
        return _widget.itemCount - 1 - _page;
      } else {
        return _page;
      }
    } catch (exception) {
      return 0.0;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_widget.itemCount < _widget.visibleDotThreshold) {
      return;
    }
    final width = orientation == Axis.horizontal ? size.width : size.height;
    final height = orientation == Axis.vertical ? size.width : size.height;

    adjustFramePosition(page, width);

    // Some empirical coefficients
    final scaleDistance = (_widget.dotSpacing + (_widget.dotSelectedSize - _widget.dotSize) / 2) * 0.7;
    final smallScaleDistance = _widget.dotSelectedSize / 2;

    final firstVisibleDotPos = ((_visibleFramePosition - _firstDotOffset) / _widget.dotSpacing).floor();
    var lastVisibleDotPos = firstVisibleDotPos +
        ((_visibleFramePosition + width - getDotOffsetAt(firstVisibleDotPos)) / _widget.dotSpacing).floor();

    // If real dots count is less than we can draw inside visible frame, we move lastVisibleDotPos
    // to the last item
    if (firstVisibleDotPos == 0 && lastVisibleDotPos + 1 > _widget.itemCount) {
      lastVisibleDotPos = _widget.itemCount - 1;
    }

    for (var i = firstVisibleDotPos; i <= lastVisibleDotPos; i++) {
      final dot = getDotOffsetAt(i);
      if (dot >= _visibleFramePosition && dot < _visibleFramePosition + width) {
        double diameter;
        double scale;

        // Calculate scale according to current page position
        scale = getDotScaleAt(i);
        diameter = lerpDouble(_widget.dotSize, _widget.dotSelectedSize, scale)!;

        // Additional scale for dots at corners
        if (_widget.itemCount > _widget.visibleDotCount) {
          double currentScaleDistance;
          if (i == 0 || i == _widget.itemCount - 1) {
            currentScaleDistance = smallScaleDistance;
          } else {
            currentScaleDistance = scaleDistance;
          }

          if (dot - _visibleFramePosition < currentScaleDistance) {
            final calculatedDiameter = diameter * (dot - _visibleFramePosition) / currentScaleDistance;
            diameter = min(diameter, calculatedDiameter);
          } else if (dot - _visibleFramePosition > width - currentScaleDistance) {
            final calculatedDiameter = diameter * (-dot + _visibleFramePosition + width) / currentScaleDistance;
            diameter = min(diameter, calculatedDiameter);
          }
        }

        _paint.color = Color.lerp(_widget.dotColor, _widget.dotSelectedColor, scale)!;

        if (orientation == Axis.horizontal) {
          canvas.drawCircle(Offset(dot - _visibleFramePosition, height / 2), diameter / 2, _paint);
        } else {
          canvas.drawCircle(Offset(height / 2, dot - _visibleFramePosition), diameter / 2, _paint);
        }
      }
    }
  }

  double getDotOffsetAt(int index) {
    return _firstDotOffset + index * _widget.dotSpacing;
  }

  double getDotScaleAt(int index) {
    final position = page.floor();
    final offset = page - position;
    if (index == position) {
      return 1 - offset.abs();
    } else if (index == position + 1 && position < _widget.itemCount - 1) {
      return 1 - (1 - offset).abs();
    }
    return 0;
  }

  void adjustFramePosition(double page, double width) {
    final position = page.floor();
    final offset = page - position;
    if (_widget.itemCount <= _widget.visibleDotCount) {
      _visibleFramePosition = 0;
    } else {
      final center = getDotOffsetAt(position) + _widget.dotSpacing * offset;
      _visibleFramePosition = center - width / 2;

      // Block frame offset near start and end
      final firstCenteredDotIndex = (_widget.visibleDotCount / 2).floor();
      final lastCenteredDot = getDotOffsetAt(_widget.itemCount - 1 - firstCenteredDotIndex);
      if (_visibleFramePosition + width / 2 < getDotOffsetAt(firstCenteredDotIndex)) {
        _visibleFramePosition = getDotOffsetAt(firstCenteredDotIndex) - width / 2;
      } else if (_visibleFramePosition + width / 2 > lastCenteredDot) {
        _visibleFramePosition = lastCenteredDot - width / 2;
      }
    }
  }

  @override
  bool shouldRepaint(_Painter oldDelegate) {
    return oldDelegate._page != _page;
  }
}
