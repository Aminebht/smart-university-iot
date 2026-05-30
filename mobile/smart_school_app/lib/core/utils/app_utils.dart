import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../constants/app_constants.dart';

// Format date and time
String formatDateTime(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);
  
  if (difference.inSeconds < 60) {
    return 'Just now';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes}m ago';
  } else if (difference.inHours < 24) {
    return '${difference.inHours}h ago';
  } else if (difference.inDays < 7) {
    return '${difference.inDays}d ago';
  } else {
    return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
  }
}

// Format date only
String formatDate(DateTime dateTime) {
  final DateFormat formatter = DateFormat('MMM dd, yyyy');
  return formatter.format(dateTime);
}

// Get status color based on device status
Color getStatusColor(DeviceStatus status) {
  switch (status) {
    case DeviceStatus.normal:
      return AppColors.success;
    case DeviceStatus.warning:
      return AppColors.warning;
    case DeviceStatus.critical:
      return AppColors.error;
    default:
      return AppColors.success;
  }
}

// Check network connectivity
Future<bool> isConnected() async {
  var connectivityResult = await Connectivity().checkConnectivity();
  return connectivityResult != ConnectivityResult.none;
}

// Show snackbar
void showSnackBar(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      duration: const Duration(seconds: 3),
    ),
  );
}

// Show loading dialog
void showLoadingDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text("Loading..."),
          ],
        ),
      );
    },
  );
}

// Parse sensor reading value with proper formatting
String formatSensorReading(double value, String unit) {
  return '${value.toStringAsFixed(1)} $unit';
}