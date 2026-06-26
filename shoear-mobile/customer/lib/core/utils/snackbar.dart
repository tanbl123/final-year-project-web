import 'package:flutter/material.dart';

/// Snackbar helpers that avoid the default queuing behaviour.
///
/// By default `ScaffoldMessenger` queues snackbars, so rapid actions (e.g.
/// tapping "Add to cart" several times) stack up and the user has to wait for
/// each to time out. These helpers dismiss the current snackbar first so the
/// latest message shows immediately.
extension SnackBarContext on BuildContext {
  /// Show [message], replacing any snackbar currently on screen.
  void showSnack(String message) {
    ScaffoldMessenger.of(this)
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Show a pre-built [snackBar], replacing any currently on screen.
  void showSnackBarNow(SnackBar snackBar) {
    ScaffoldMessenger.of(this)
      ..removeCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}
