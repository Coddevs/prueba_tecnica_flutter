import 'dart:async';
import 'package:flutter/material.dart';
import 'package:scheduling/src/widgets/state_widget.dart';

@immutable
abstract class Functions {
  static void showSnackBar({
    required BuildContext context,
    Duration duration = const Duration(seconds: 5),
    required Text content,
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: duration,
        content: content,
      ),
    );
  }

  static Future<void> showPause({
    required BuildContext context,
    required Future<void> Function(BuildContext) future,
    FutureOr<void> Function()? onSuccess,
    FutureOr<void> Function(Object)? onError,
  }) {
    final completer = Completer<void>();

    showModalBottomSheet(
      isDismissible: false,
      enableDrag: false,
      context: context,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: StateWidget(
            child: const LinearProgressIndicator(minHeight: 7.5),
            onPostInit: () async {
              final navigator = Navigator.of(context);
              try {
                await future.call(context);
                navigator.pop();
                await onSuccess?.call();
                completer.complete();
              } catch (error) {
                navigator.pop();
                await onError?.call(error);
                completer.complete();
              }
            },
          ),
        );
      },
    );

    return completer.future;
  }
}
