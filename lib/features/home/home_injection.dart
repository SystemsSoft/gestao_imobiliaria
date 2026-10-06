import 'package:get_it/get_it.dart';

import 'presentation/viewmodels/home_viewmodel.dart';

void registrarHome(GetIt sl) {
  sl.registerFactory(HomeViewModel.new);
}
