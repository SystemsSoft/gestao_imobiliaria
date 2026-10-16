import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/api/api_config.dart';
import 'core/api/sessao_api.dart';
import 'core/di/injector.dart';
import 'features/auth/presentation/pages/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configurarDependencias(apiUrl: ApiConfig.url);
  if (sl.isRegistered<SessaoApi>()) {
    // Sessão encerrada, desativada ou expirada: volta ao login com o motivo.
    sl<SessaoApi>().aoExpirar = (mensagem) =>
        navegadorGlobal.currentState?.pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => LoginPage(aviso: mensagem)),
          (_) => false,
        );
  }
  runApp(const MarceloImobApp());
}
