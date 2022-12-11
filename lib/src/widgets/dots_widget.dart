import 'package:flutter/material.dart';
import 'package:scheduling/src/widgets/dot_icon_widget.dart';

enum AnimationType {
  scaling,
  jumping;

  bool get isScaling => this==scaling;

  bool get isJumping => this==jumping;
}

@immutable
class DotsWidget extends StatefulWidget {
  const DotsWidget({
    super.key,
    required this.animation,
    this.length = 3,
    this.color = Colors.red,
    this.width,
    this.height,
    this.vertical = -20.0,
    this.duration = const Duration(milliseconds: 300),
  }) :
    assert(length>0, '[length] must be greater than 0.'),
    assert(vertical!=0.0, '[vertical] must be different from 0.');

  final AnimationType animation;
  final int length;
  final Color color;
  final double? width;
  final double? height;
  final double vertical;
  final Duration duration;

  @override
  State createState() => _DotsWidgetState();
}
class _DotsWidgetState extends State<DotsWidget>
  with TickerProviderStateMixin {

  final _controllers = <AnimationController>[];
  final _animations = <Animation<double>>[];
  var _currentAnimationIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.length, (index) {
        return AnimatedBuilder(
          animation: _controllers[index],
          builder: (context, child) {
            final dotIcon = DotIconWidget(
              active: index==_currentAnimationIndex,
              color: widget.color,
              width: widget.width ?? theme.iconTheme.size ?? 24.0,
              height: widget.height ?? theme.iconTheme.size ?? 24.0,
            );
            return Padding(
              padding: const EdgeInsets.all(2.5),
              child: widget.animation.isScaling
                    ? Transform.scale(
                      scale: _animations[index].value,
                      child: dotIcon,
                    ) : Transform.translate(
                      offset: Offset(0, _animations[index].value),
                      child: dotIcon,
                    ),
            );
          },
        );
      }).toList(),
    );
  }

  @override
  void initState() {
    super.initState();
    for (var i=0; i<widget.length; i++) {
      _controllers.add(
        AnimationController(
          duration: widget.duration,
          vsync: this,
        ),
      );

      _animations.add(
        Tween<double>(
          begin: widget.animation.isScaling ? 1.0 : 0.0,
          end: widget.animation.isScaling ? 1.50 : widget.vertical,
        ).animate(_controllers[i]),
      );

      _controllers[i].addStatusListener((status) {
        if (status==AnimationStatus.completed) {
          _controllers[i].reverse();

          if (i!=widget.length-1) {
            _controllers[i + 1].forward();
            _currentAnimationIndex = i + 1;
          }
        }

        if (i==widget.length-1 && status==AnimationStatus.dismissed) {
          _controllers[0].forward();
          _currentAnimationIndex = 0;
        }
      });
    }

    _controllers.first.forward();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
