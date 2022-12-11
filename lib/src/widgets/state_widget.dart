import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

@immutable
class StateWidget extends StatefulWidget {
  const StateWidget({
    super.key,
    required this.child,
    this.onInit,
    this.onPostInit,
    this.onDispose,
    this.onPostDispose,
  });

  final Widget child;
  final VoidCallback? onInit;
  final VoidCallback? onPostInit;
  final VoidCallback? onDispose;
  final VoidCallback? onPostDispose;

  @override
  State createState() => _StateWidgetState();
}
class _StateWidgetState extends State<StateWidget>
  with WidgetsBindingObserver {

  @override
  Widget build(BuildContext context) => widget.child;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.onInit?.call();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      widget.onPostInit?.call();
    });
  }

  @override
  void dispose() {
    widget.onDispose?.call();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      widget.onPostDispose?.call();
    });
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
