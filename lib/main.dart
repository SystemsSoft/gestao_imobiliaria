import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/api/api_config.dart';
import 'core/di/injector.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configurarDependencias(apiUrl: ApiConfig.url);
  runApp(const MarceloImobApp());
}
