import 'package:flutter/material.dart';
import '../constants/colors.dart';

class NotificationService {
  static void showNotification(BuildContext context, String message,
      {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color ?? AppColors.teal,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showSuccessNotification(BuildContext context, String message) {
    showNotification(context, message, color: AppColors.green);
  }

  static void showErrorNotification(BuildContext context, String message) {
    showNotification(context, message, color: AppColors.red);
  }

  static void showInfoNotification(BuildContext context, String message) {
    showNotification(context, message, color: AppColors.blue);
  }
}
