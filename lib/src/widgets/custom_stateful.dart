import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

@immutable
class CustomStateful extends StatefulWidget {
  const CustomStateful({
    final Key? key,
    this.controller,
    required this.builder,
  }) : super(key: key);

  final StateController? controller;
  final WidgetBuilder builder;

  @override
  State createState() => _CustomStatefulState();
}
class _CustomStatefulState extends State<CustomStateful> {
  void _repaint(VoidCallback callback) {
    try {
      setState(callback);
    } catch (_) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(callback);
        } else {
          callback.call();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }

  @override
  void initState() {
    super.initState();
    widget.controller?._repaint = _repaint;
  }
}

class StateController {
  void repaint(VoidCallback callback) => _repaint(callback);

  @mustCallSuper
  void dispose() {
    _repaint = (_) {};
  }

  ValueSetter<VoidCallback> _repaint = (_) {};
}
