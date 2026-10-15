import 'package:flutter/material.dart';

import 'core/api/api_config.dart';
import 'core/di/injector.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configurarDependencias(apiUrl: ApiConfig.url);
  runApp(MaterialApp(theme: buildAppTheme(), home: const HomePage()));
}
