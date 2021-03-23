import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

class ScrollingPageIndicator extends StatefulWidget {

  final double dotSize;

  final double dotSelectedSize;

  final Color? dotColor;

  final Color dotSelectedColor;

  final double dotSpacing;

  final int visibleDotCount;

  final int visibleDotThreshold;

  final int? itemCount;

  final PageController? controller;

  final Axis orientation;

  final bool reverse;

  ScrollingPageIndicator({
    Key? key,
    this.dotSize: 6.0,
    this.dotSelectedSize: 10.0,
    this.dotColor: Colors.grey,
    this.dotSelectedColor: Colors.blueGrey,
    this.dotSpacing: 12.0,
    this.visibleDotCount = 5,
    this.visibleDotThreshold = 2,
    this.itemCount,
    this.controller,
    this.orientation = Axis.horizontal,
    this.reverse = false
  })
      : assert(itemCount != null),
        assert(controller != null),
        assert(visibleDotCount % 2 != 0),
        super(key: key);

  @override
  State<StatefulWidget> createState() {
    return new _ScrollingPageIndicatorState();
  }
}

class _ScrollingPageIndicatorState extends State<ScrollingPageIndicator> {

  double _page = 0;

  Paint _paint = new Paint();


  @override
  void initState() {
    widget.controller!.addListener(_onController);
    super.initState();
  }

  @override
  void didUpdateWidget(ScrollingPageIndicator oldWidget) {
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller!.removeListener(_onController);
      widget.controller!.addListener(_onController);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    widget.controller!.removeListener(_onController);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int itemCount = (widget.itemCount! >= widget.visibleDotCount ? widget.visibleDotCount : widget
        .itemCount)!;
    double width = (itemCount - 1) * widget.dotSpacing + widget.dotSelectedSize;
    Widget child = new SizedBox(
        width: widget.orientation == Axis.horizontal ? width : widget.dotSelectedSize,
        height: widget.orientation == Axis.vertical ? width : widget.dotSelectedSize,
        child: new CustomPaint(painter: _Painter(widget, currentPage, _paint, widget.orientation)));
    return new IgnorePointer(
      child: child,
    );
  }

  double get currentPage {
    try {
      return widget.controller!.page ?? 0.0;
    } catch (Exception) {
      return 0.0;
    }
  }

  void _onController() {
    setState(() {});
  }

}

class _Painter extends CustomPainter {

  final ScrollingPageIndicator _widget;
  final double _page;
  final Paint _paint;
  final Axis orientation;

  double? _visibleFramePosition;

  double? _firstDotOffset;

  _Painter(this._widget, this._page, this._paint, this.orientation) {
    _firstDotOffset = _widget.itemCount! > _widget.visibleDotCount ? 0 : _widget.dotSelectedSize / 2;
  }

  double get page {
    try {
      if(_widget.reverse){
        return _widget.itemCount!-1-_page;
      }else{
        return _page;
      }
    } catch (Exception) {
      return 0.0;
    }
  }


  @override
  void paint(Canvas canvas, Size size) {
    if (_widget.itemCount! < _widget.visibleDotThreshold) {
      return;
    }
    double width = orientation == Axis.horizontal ? size.width : size.height;
    double height = orientation == Axis.vertical ? size.width : size.height;

    adjustFramePosition(page, width);

    // Some empirical coefficients
    double scaleDistance = (_widget.dotSpacing + (_widget.dotSelectedSize - _widget.dotSize) / 2) *
        0.7;
    double smallScaleDistance = _widget.dotSelectedSize / 2;

    int firstVisibleDotPos = ((_visibleFramePosition! - _firstDotOffset!) / _widget.dotSpacing)
        .floor();
    int lastVisibleDotPos = firstVisibleDotPos +
        ((_visibleFramePosition! + width - getDotOffsetAt(firstVisibleDotPos)) /
            _widget.dotSpacing)
            .floor();

    // If real dots count is less than we can draw inside visible frame, we move lastVisibleDotPos
    // to the last item
    if (firstVisibleDotPos == 0 && lastVisibleDotPos + 1 > _widget.itemCount!) {
      lastVisibleDotPos = _widget.itemCount! - 1;
    }

    for (int i = firstVisibleDotPos; i <= lastVisibleDotPos; i++) {
      double dot = getDotOffsetAt(i);
      if (dot >= _visibleFramePosition! && dot < _visibleFramePosition! + width) {
        double diameter;
        double scale;

        // Calculate scale according to current page position
        scale = getDotScaleAt(i);
        diameter = lerpDouble(_widget.dotSize, _widget.dotSelectedSize, scale)!;

        // Additional scale for dots at corners
        if (_widget.itemCount! > _widget.visibleDotCount) {
          double currentScaleDistance;
          if ((i == 0 || i == _widget.itemCount! - 1)) {
            currentScaleDistance = smallScaleDistance;
          } else {
            currentScaleDistance = scaleDistance;
          }

          if (dot - _visibleFramePosition! < currentScaleDistance) {
            double calculatedDiameter = diameter * (dot - _visibleFramePosition!) /
                currentScaleDistance;
            diameter = min(diameter, calculatedDiameter);
          } else if (dot - _visibleFramePosition! > width - currentScaleDistance) {
            double calculatedDiameter =
                diameter * (-dot + _visibleFramePosition! + width) / currentScaleDistance;
            diameter = min(diameter, calculatedDiameter);
          }
        }

        _paint.color = Color.lerp(_widget.dotColor!, _widget.dotSelectedColor, scale)!;

        if (orientation == Axis.horizontal) {
          canvas.drawCircle(
              new Offset(dot - _visibleFramePosition!, height / 2), diameter / 2, _paint);
        } else {
          canvas.drawCircle(
              new Offset(height / 2, dot - _visibleFramePosition!), diameter / 2, _paint);
        }
      }
    }
  }

  double getDotOffsetAt(int index) {
    return _firstDotOffset! + index * _widget.dotSpacing;
  }

  double getDotScaleAt(int index) {
    int position = page.floor();
    double offset = page - position;
    if (index == position) {
      return 1 - offset.abs();
    } else if (index == position + 1 && position < _widget.itemCount! - 1) {
      return 1 - (1 - offset).abs();
    }
    return 0;
  }

  void adjustFramePosition(double page, double width) {
    int position = page.floor();
    double offset = page - position;
    if (_widget.itemCount! <= _widget.visibleDotCount) {
      _visibleFramePosition = 0;
    } else {
      double center = getDotOffsetAt(position) + _widget.dotSpacing * offset;
      _visibleFramePosition = center - width / 2;

      // Block frame offset near start and end
      int firstCenteredDotIndex = (_widget.visibleDotCount / 2).floor();
      double lastCenteredDot = getDotOffsetAt(_widget.itemCount! - 1 - firstCenteredDotIndex);
      if (_visibleFramePosition! + width / 2 < getDotOffsetAt(firstCenteredDotIndex)) {
        _visibleFramePosition = getDotOffsetAt(firstCenteredDotIndex) - width / 2;
      } else if (_visibleFramePosition! + width / 2 > lastCenteredDot) {
        _visibleFramePosition = lastCenteredDot - width / 2;
      }
    }
  }

  @override
  bool shouldRepaint(_Painter oldDelegate) {
    return oldDelegate._page != _page;
  }

}
