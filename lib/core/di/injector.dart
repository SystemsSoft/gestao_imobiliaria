import 'package:get_it/get_it.dart';

import '../../features/auth/auth_injection.dart';
import '../../features/crm/crm_injection.dart';
import '../../features/home/home_injection.dart';
import '../../features/locacao/locacao_injection.dart';

/// Localizador de serviços da aplicação.
final sl = GetIt.instance;

/// Registra as dependências de todas as features.
Future<void> configurarDependencias() async {
  await sl.reset();
  registrarAuth(sl);
  registrarHome(sl);
  registrarCrm(sl);
  registrarLocacao(sl);
}
