import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

bool isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

const themeSeedColor = Color(0xFFd16d6a);

final urlBase = String.fromEnvironment(
  'API_BASE',
  defaultValue: !isMobile ? 'http://127.0.0.1:8000' : '',
);

final sharedPrefs = SharedPreferencesAsync();
