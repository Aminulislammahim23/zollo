import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_colors.dart';
import 'app_button.dart';
import 'empty_state.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    this.error,
    this.message,
    this.onRetry,
    this.title = 'Something went wrong',
  });

  final Object? error;
  final String? message;
  final VoidCallback? onRetry;
  final String title;

  /// Turns exceptions into a sentence a shopper can read.
  static String describe(Object? error) {
    if (error == null) return 'Please try again.';
    if (error is AuthException) return error.message;
    if (error is PostgrestException) return error.message;
    if (error is StateError) return error.message;
    final text = error.toString();
    if (text.contains('SocketException') || text.contains('Failed host lookup')) {
      return 'No internet connection. Check your network and try again.';
    }
    return text.replaceFirst('Exception: ', '').replaceFirst('Bad state: ', '');
  }

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.error_outline,
      iconColor: AppColors.error,
      iconBackground: AppColors.errorBg,
      title: title,
      message: message ?? describe(error),
      actionLabel: onRetry == null ? null : 'Try again',
      onAction: onRetry,
      actionVariant: AppButtonVariant.outline,
    );
  }
}
