import 'dart:io';
import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';

bool isMobile = Platform.isAndroid || Platform.isIOS;

const themeSeedColor = Color(0xFFd16d6a);

const urlBase = '127.0.0.1';

final sharedPrefs = SharedPreferencesAsync();
