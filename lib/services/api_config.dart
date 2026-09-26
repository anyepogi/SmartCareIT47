import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  ApiConfig._();

  /* This tells the app what web address to use when it talks to the PHP
  backend. The production backend is hosted on Hostinger using HTTPS.
  All platforms use the same public domain instead of localhost. */
  static String get baseUrl {
    if (kIsWeb) {
      return 'https://smartcare-ccs.com';
    }
    if (Platform.isAndroid) {
      return 'https://smartcare-ccs.com';
    }
    return 'https://smartcare-ccs.com';
  }
}
