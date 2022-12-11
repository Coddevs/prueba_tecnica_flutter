import 'package:flutter/material.dart';
import 'package:scheduling/src/widgets/dots_widget.dart';

@immutable
class FutureWidget<T> extends StatelessWidget {
  const FutureWidget({
    super.key,
    required this.future,
    required this.setState,
    required this.initialData,
    required this.computeWhere,
    required this.onDataChanged,
    this.indicatorBuilder,
    this.errorViewBuilder,
    required this.builder,
  });

  final Future<T> future;
  final StateSetter setState;
  final ValueGetter<T> initialData;
  final ValueGetter<bool> computeWhere;
  final ValueSetter<T> onDataChanged;
  final Widget Function(
    BuildContext context,
    Widget indicator,
  )? indicatorBuilder;
  final Widget Function(
    BuildContext context,
    Widget errorView,
    Object? errorObj,
  )? errorViewBuilder;
  final Widget Function(
    BuildContext context,
    Widget? indicator,
    Widget? errorView,
    T? data,
  ) builder;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final defaultIndicator = DotsWidget(
      animation: AnimationType.scaling,
      color: textTheme.bodyText1?.color ?? Colors.red,
      width: 15.0,
      height: 15.0,
    );
    final indicatorBox = indicatorBuilder!=null
                        ? indicatorBuilder!.call(context, defaultIndicator)
                        : defaultIndicator;
    var computing = computeWhere();
    return FutureBuilder<T>(
      future: Future.microtask(() async {
        if (computeWhere()) {
          computing = true;
          return future.then((data) {
            computing = false;
            onDataChanged(data);
            return data;
          });
        } else {
          return initialData.call();
        }
      }),
      builder: (context, snapshot) {
        final isWaiting = snapshot.connectionState==ConnectionState.waiting;
        if (snapshot.hasError && !isWaiting) {
          final defaultErrorBox = Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error: ${snapshot.error}',
                style: textTheme.headline6,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12.5),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => setState(() {}),
              ),
            ],
          );
          final errorBox = errorViewBuilder!=null
                          ? errorViewBuilder!.call(
                              context,
                              defaultErrorBox,
                              snapshot.error,
                            )
                          : defaultErrorBox;
          return builder(context, null, errorBox, null);
        } else if (snapshot.hasData && !computing) {
          return builder(context, null, null, snapshot.data);
        } else {
          return builder(context, indicatorBox, null, null);
        }
      },
    );
  }
}
