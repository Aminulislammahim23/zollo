import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';

/// Opens an email to zollo support, falling back to a SnackBar with the
/// address when no mail app is available.
Future<void> contactSupport(BuildContext context, {String? subject}) async {
  final uri = Uri(
    scheme: 'mailto',
    path: AppConstants.supportEmail,
    query: subject == null ? null : 'subject=${Uri.encodeComponent(subject)}',
  );
  var opened = false;
  try {
    opened = await launchUrl(uri);
  } catch (_) {
    opened = false;
  }
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email us at ${AppConstants.supportEmail}')),
    );
  }
}

/// Opens [url] in the browser, with a SnackBar if that fails.
Future<void> openExternalUrl(BuildContext context, String url) async {
  var opened = false;
  try {
    opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  } catch (_) {
    opened = false;
  }
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Couldn't open $url")));
  }
}
