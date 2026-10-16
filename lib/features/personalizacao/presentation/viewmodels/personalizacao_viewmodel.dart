import 'dart:typed_data';

import '../../../../core/config/empresa_info.dart';
import '../../../../core/presentation/view_model.dart';
import '../../domain/usecases/personalizacao_usecases.dart';

class PersonalizacaoViewModel extends ViewModel {
  PersonalizacaoViewModel(
    this._carregar,
    this._salvarDados,
    this._salvarLogo,
    this._removerLogo,
  ) {
    _iniciar();
  }

  final CarregarPersonalizacao _carregar;
  final SalvarDadosEmpresa _salvarDados;
  final SalvarLogo _salvarLogo;
  final RemoverLogo _removerLogo;

  bool carregado = false;

  DadosEmpresa get dados => EmpresaInfo.atual;
  Uint8List? get logo => EmpresaInfo.logo;

  Future<void> _iniciar() async {
    await executar(_carregar.call);
    carregado = true;
    notificar();
  }

  Future<bool> salvar(DadosEmpresa d) => executar(() => _salvarDados(d));
  Future<bool> trocarLogo(Uint8List imagem) =>
      executar(() => _salvarLogo(imagem));
  Future<bool> usarLogoPadrao() => executar(_removerLogo.call);
}
