import 'package:flutter/foundation.dart';

class RetryController {
  RetryController({required this.onRetryRequested});

  final VoidCallback onRetryRequested;

  void retry() {
    onRetryRequested();
  }
}
