import 'package:flutter/material.dart';
import 'package:maki_app/widgets/error_state.dart';

class AsyncStateView extends StatelessWidget {
  const AsyncStateView({
    super.key,
    required this.isLoading,
    required this.child,
    this.errorMessage,
    this.onRetry,
    this.isEmpty = false,
    this.empty,
    this.loading,
  });

  final bool isLoading;

  final String? errorMessage;
  final VoidCallback? onRetry;

  final bool isEmpty;

  final Widget? empty;

  final Widget? loading;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return loading ?? const Center(child: CircularProgressIndicator());
    }
    if (errorMessage != null) {
      return ErrorState(message: errorMessage!, onRetry: onRetry);
    }
    if (isEmpty && empty != null) {
      return empty!;
    }
    return child;
  }
}
